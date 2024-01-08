# == Schema Information
#
# Table name: business_transactions
#
#  id                :integer          not null, primary key
#  description       :string
#  later_balance     :decimal(19, 4)
#  order             :integer          default(1)
#  origin_type       :string
#  previous_balance  :decimal(19, 4)
#  reversed          :boolean          default(FALSE)
#  transaction_date  :datetime
#  transaction_value :decimal(19, 4)   default(0.0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  balance_id        :integer
#  external_id       :string
#  origin_id         :bigint
#  reference_id      :integer
#
# Indexes
#
#  index_business_transactions_on_balance_id                 (balance_id)
#  index_business_transactions_on_external_id                (external_id)
#  index_business_transactions_on_origin_id_and_origin_type  (origin_id,origin_type)
#
require 'spreadsheet'

class BusinessTransaction < ApplicationRecord
  include ObjectActions::ObjectActionHelper
  include ApplicationHelper
  include Formatter

  has_paper_trail limit: 1

  belongs_to :balance, optional: true
  belongs_to :origin, polymorphic: true, optional: true

  has_one    :property,  through: :balance

  before_create :default_transaction_date
  after_create :apply_transaction
  after_create :construct_description

  before_destroy :undo_transaction
  after_destroy :update_property_future

  scope :without_nullified_payments, lambda {
    joins(
      <<~SQL
        left join payments AS p
          on business_transactions.origin_id = p.id
          and business_transactions.origin_type = 'Payment'
          and p.nullified
      SQL
    )
      .where('p.id is NULL')
  }

  scope :with_only_adjustments_or_condonation, -> do
    joins(
      <<~SQL
        join payments
          on business_transactions.origin_id = payments.id
          and business_transactions.origin_type = 'Payment'
      SQL
    )
    .where(payments: { payment_type: Payment.payment_types.values_at(:adjustment, :debt_relief) })
  end

  scope :without_adjustments_or_condonation, -> do
    joins(
      <<~SQL
        join payments
          on business_transactions.origin_id = payments.id
          and business_transactions.origin_type = 'Payment'
      SQL
    )
    .where.not(payments: { payment_type: Payment.payment_types.values_at(:adjustment, :debt_relief) })
  end

  scope :with_public_later_balance, -> do
    select(
      <<~SQL
        case
          when coalesce(s.value, 0) = 0 then -1 * business_transactions.later_balance
          else business_transactions.later_balance
        end public_later_balance
      SQL
    )
    .joins(property: :community)
    .joins(
      <<~SQL
        left join settings s on s.community_id = communities.id and s.code = 'invert_balances'
      SQL
    )
  end

  #This scope was created to format date fields that will be shown in tables with text filters
  scope :with_formatted_date, -> (field, field_alias) do
    select(
      <<~SQL
        replace(
          to_char(#{field}, 'dd {mnth} yyyy'),
          '{mnth}',
          case extract(
              month from #{field}
            )
            #{(1..12).map { |i| "when #{i} then \'" + I18n.t('date.month_names')[i] + "'\n" }.join('')}
          end
        ) #{field_alias}
      SQL
    )
  end

  scope :summary_statement, -> (balance_id, start_date = nil, end_date = nil) do
    query =
      from(
        <<~SQL
          (
            SELECT
              bt.id,
              bt.description,
              bt.transaction_date,
              bt.order,
              bt.transaction_value,
              bt.external_id,
              bt.origin_type,
              bt.origin_id,
              bt.balance_id,
              0
            FROM business_transactions bt
            WHERE balance_id = #{ balance_id } and origin_type != 'Interest'
            UNION
            SELECT
              0 as id,
              concat('Interes sobre ', ce.name) as description,
              min(bt_int.transaction_date ) + interval '5 seconds' as transaction_date,
              0 as order,
              sum(bt.transaction_value) as transaction_value,
              '' as  external_id,
              bt.origin_type as origin_type,
              0 as origin_id,
              bt.balance_id,
              ce.id as origin_debt
            FROM business_transactions bt
            JOIN interests i on bt.origin_id = i.id and bt.origin_type = 'Interest'
            JOIN debts d on d.id = i.origin_debt_id
            JOIN common_expenses ce on ce.id = d.common_expense_id
            JOIN business_transactions bt_int on bt_int.id = ce.property_transaction_id
            WHERE bt.balance_id = #{ balance_id }
            GROUP BY origin_debt, ce.name, bt.origin_type, bt.balance_id
          ) as data
        SQL
      )

    query = query.where('transaction_date >= ?', start_date) if start_date.present?
    query = query.where('transaction_date <= ?', end_date) if end_date.present?

    query.order('data.transaction_date desc, data.order desc, data.id desc')
  end

  scope :descending_order, lambda { |custom_date = nil|
    query = self

    custom_date.present? ? query.order!(Arel.sql("COALESCE(#{custom_date}, business_transactions.transaction_date) DESC")) : query.order!(transaction_date: :desc)
    query.order!(order: :desc, id: :desc)

    query
  }

  scope :between_dates, lambda { |from_date = nil, until_date = nil, custom_comparison_date = nil|
    query = self

    # If you use a custom column from other association to compare, be sure that the necessary joins are made in the query
    transaction_date = custom_comparison_date.present? ? "COALESCE(#{custom_comparison_date}, business_transactions.transaction_date)" : 'business_transactions.transaction_date'

    query.where!("#{transaction_date} >= ?", from_date) if from_date
    query.where!("#{transaction_date} <= ?", until_date) if until_date

    query
  }

  scope :with_payments_paid_at_as_transaction_date, lambda {
    joins("LEFT JOIN payments ON payments.id = business_transactions.origin_id AND business_transactions.origin_type = 'Payment'")
      .select('business_transactions.*, COALESCE(payments.paid_at, business_transactions.transaction_date) AS transaction_date')
  }

  def default_transaction_date
    self.transaction_date ||= Time.now
  end

  def apply_transaction
    b = Balance.find(self.balance_id)
    self.previous_balance = b.money_balance
    b.money_balance += self.transaction_value
    b.save
    self.later_balance = b.money_balance
    self.save
  end

  # SOLO CUANDO SE DESTRUYE LA TRANSACCION. PARA ANULAR SE DEBE CREAR OTRA BusinessTransaction
  def undo_transaction
    b = self.balance
    b.money_balance -= self.transaction_value
    throw(:abort) unless b.save
  end

  def update_property_future
    b = Balance.find_by(id: self.balance_id)
    return unless b.present?
    b.update_property_future
  end

  def get_before_transaction
    balance.business_transactions.where('transaction_date < ?', self.transaction_date).order('transaction_date desc').first
  end

  def get_next_transaction
    balance.business_transactions.where('transaction_date > ?', self.transaction_date).order('transaction_date asc').first
  end

  def get_folio
    if self.origin_type == 'Payment'
      payment = Payment.find_by_id(self.origin_id)
      return payment.present? ? payment.folio : ''
    else
      return ''
    end
  end

  def has_pdf
    return false unless %w[Payment CommonExpense PropertyFine].include?(origin_type)

    origin&.has_pdf_for_business_transaction?
  end

  def get_pdf_url(host_url = nil)
    pdf_url = case origin_type
              when 'Payment'
                origin&.receipt&.expiring_url(20)
              when 'CommonExpense'
                origin&.bill&.bill&.expiring_url(20)
              when 'PropertyFine'
                "#{host_url}#{Rails.application.routes.url_helpers.property_fine_path(format: :pdf, id: origin&.id)}"
              end
    url?(pdf_url) ? pdf_url : nil
  end

  def destroy_transaction
    destroy

    # It isn't the last
    if get_before_transaction.present?
      get_before_transaction.update_future
    else # Is the last
      get_next_transaction.update(previous_balance: 0)
      get_next_transaction.update_future
    end
  end

  def public_later_balance community: nil
    community ||= balance.get_owner_community
    get_value_for_balance( later_balance, community)
  end

  def public_previous_balance community: nil
    community ||= balance.get_owner_community
    get_value_for_balance( previous_balance, community)
  end

  def get_value_for_balance value, community
    (value != 0 and community.get_setting_value('invert_balances').zero? ) ? value * -1 : value
  end


  def update_future
    balance = self.balance
    business_transactions = balance.business_transactions
                                   .where('"transaction_date" > ? OR ("transaction_date" = ? AND "order" >= ?)', self.transaction_date, self.transaction_date, self.order)
                                   .order(:transaction_date, :order, :id)

    current_balance = self.previous_balance.to_f
    business_transactions.each do |t|
      t.previous_balance = current_balance
      t.later_balance = t.previous_balance + t.transaction_value
      t.save
      current_balance = t.later_balance
    end

    balance.money_balance = current_balance
    balance.save
  end

  def construct_description force = false
    return if self.description.present? && !force

    object = self.origin

    case self.origin_type
    when 'CommonExpense'
      description = origin.name if origin.present?
    when 'Interest'
      interest = Interest.find(self.origin_id)
      description = I18n.t('models.business_transaction.construct_description.interest_description', amount: to_currency(amount: interest.base_price, community: self.balance.community))
    when 'Payment'
      description = object.business_transaction_description if object.present?
    when 'ExcelUpload'
      description = self.transaction_value > 0 ? 'Abono importado desde excel' :  'Cargo importado desde excel'
    end

    self.update description: description if description.present?
    return description
  end


  def self.generate_excel_sheet business_transactions, name, prop, community
    # Title
    property_sheet = {}
    property_sheet[:name] = name
    property_sheet[:title] = ['', "#{I18n.t('views.bills.business_transaction.one')} de "+ I18n.t('activerecord.models.property.one') +" #{prop}"]
    property_sheet[:sub_title] = ['', community.to_s]
    property_sheet[:body] = []

    statement_header = ['', 'Fecha de ingreso', 'Cargo', 'Abono', 'Descripción', 'Saldo']
    data_format = Hash.new('')
    data_format['Fecha de ingreso'] = 'date'
    data_format['Cargo'] = 'price'
    data_format['Abono'] = 'price'
    data_format['Saldo'] = 'price'
    statement_style = statement_header.map{ |h| data_format[h] }

    property_sheet[:header] = statement_header
    property_sheet[:style] = statement_style

    business_transactions.each do |b|
      transaction_date = I18n.l(TimeZone.get_local_time(date_time: b.transaction_date, community: community), format: :default_hyphen)
      charge = b.transaction_value.negative? ? b.transaction_value.abs.to_i : 0
      balance = b.later_balance != 0 ? b.later_balance * -1 : b.later_balance
      payment = b.transaction_value.negative? ? 0 : b.transaction_value.abs.to_i
      property_sheet[:body].append(
        content: ['', transaction_date, charge, payment, b.description.to_s, balance],
        style: { alternated: true }
      )
    end
    property_sheet
  end

  def self.generate_excel_book properties, community
    document = []
    book_sheet = {}
    book_sheet[:name] = 'Índice'
    book_sheet[:title] = ['', 'Índice']
    book_sheet[:sub_title] = ['', community.to_s ]
    book_sheet[:body] = []

    statement_header = ['', 'ID', I18n.t('activerecord.models.property.one'), "Link a #{I18n.t('views.bills.business_transaction.one').downcase}"]
    statement_style = ['', '', '', '', '', '', '']

    book_sheet[:header] = statement_header
    book_sheet[:style] = statement_style

    # Rows
    property_sheets = []
    properties.each_with_index do |prop, index|
      sheet_name = prop.to_s
      book_sheet[:body].append({
        content: ['', prop.id, prop.to_s, "ver #{I18n.t('views.bills.business_transaction.one').downcase}"],
        style: { alternated: true },
        hyperlink: { location: "#{sheet_name}!A1", target: :sheet, col: 3 }
      })
      property_sheets.push(generate_excel_sheet(prop.balance.ordered_business_transactions, sheet_name, prop, community))
    end
    document.push(book_sheet)
    document += property_sheets
    format_to_excel(document, community)
  end

  def get_payment
    origin_type == 'Payment' ? origin : nil
  end

  def localized_origin_type
    case origin_type
    when 'CommonExpense'
      I18n.t('activerecord.attributes.payment.origin_type.common_expense')
    when 'Interest'
      I18n.t('activerecord.attributes.payment.origin_type.interest')
    when 'Payment'
      I18n.t('activerecord.attributes.payment.origin_type.payment')
    when 'PropertyFine'
      I18n.t('activerecord.attributes.payment.origin_type.property_fine')
    else
      description
    end
  end

  def self.update_all_business_transactions(community_id)
    Balance.joins(:property)
           .joins(%(LEFT JOIN "business_transactions" ON "business_transactions"."balance_id" = "balances"."id"))
           .where(properties: { community_id: community_id })
           .where(business_transactions: { id: nil })
           .update_all(money_balance: 0)
    BusinessTransaction.joins(balance: :property)
                       .where(properties: { community_id: community_id })
                       .order('properties.id').order(:transaction_date, :order)
                       .select('distinct on (properties.id) business_transactions.*')
                       .each do |bt|
                         bt.previous_balance = 0
                         bt.update_future
                       end
  end

  def self.excel_import(params, community, excel_upload, property)
    balance = property.balance
    excel_params = excel_params(params)
    business_transaction = BusinessTransaction.find_by(id: excel_params[:id].to_s) if excel_params[:id].present?
    business_transaction = BusinessTransaction.find_by(external_id: excel_params[:external_id].to_s) if business_transaction.blank? && excel_params[:external_id].present?
    business_transaction = BusinessTransaction.new(balance_id: balance.id, origin_id: excel_upload.id, origin_type: excel_upload.class.name) if business_transaction.blank?
    # casecmp compara strings case insensitive. Si es cero son iguales.
    if params[:destroy].to_s.casecmp(true.to_s).zero?
      business_transaction.destroy if business_transaction&.id.present?
      return
    else
      business_transaction.assign_attributes(excel_params(params))
    end
    business_transaction
  end

  def self.excel_params(params)
    params.require(:business_transaction).permit(:transaction_value, :description, :transaction_date, :external_id)
  end

  def self.undo_excel_import(excel_upload)
    to_destroy = BusinessTransaction.where(origin_id: excel_upload.id, origin_type: excel_upload.class.name).includes(:balance).order(transaction_date: :desc, order: :desc)
    to_destroy.destroy_all
  end

  def self.reorder_excel_transactions(excel_upload_id)
    sql = %(
      UPDATE "business_transactions"
      SET "order" = "row_num"
      FROM (
        SELECT "id",
        ROW_NUMBER() OVER (PARTITION BY "balance_id", "created_at" ORDER BY "id") AS row_num
        FROM "business_transactions"
        WHERE "origin_type" = 'ExcelUpload'
          AND "origin_id" = #{excel_upload_id}
      ) A
      WHERE A."id" = "business_transactions"."id"
    )
    ActiveRecord::Base.connection.execute(sql)
  end
end
