# == Schema Information
#
# Table name: employees
#
#  id                  :integer          not null, primary key
#  active              :boolean          default(TRUE)
#  address             :string
#  born_at             :datetime
#  citizenship         :string
#  email               :string
#  father_last_name    :string
#  first_name          :string
#  foreign_citizenship :string
#  importer_type       :string
#  mother_last_name    :string
#  name                :string
#  phone               :string
#  photo               :string
#  photo_updated_at    :datetime
#  position            :string
#  rut                 :string
#  rut_afiliado        :string
#  sexo                :string
#  spouse_father_name  :string
#  spouse_first_name   :string
#  spouse_mother_name  :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  community_id        :integer
#  comuna_id           :string
#  importer_id         :integer
#  region_id           :string
#
# Indexes
#
#  index_employees_on_community_id                   (community_id)
#  index_employees_on_importer_type_and_importer_id  (importer_type,importer_id)
#
class Employee < ApplicationRecord
  include Formatter
  include RutFormatter
  include DifferenceTimes
  include AttachmentTimerUpdater
  include Employees

  attr_accessor :has_active_salary_payment, :has_past_active_salary

  has_one    :active_finiquito, -> { where(nullified: false, validated: true) }, class_name: "Finiquito"
  has_one    :active_salary, -> { where(active: true) }, class_name: 'Salary'
  has_many   :advances, -> { where(active: true) }
  belongs_to :community, optional: true
  belongs_to :comuna, optional: true
  has_many   :finiquitos, dependent: :destroy
  has_many   :nullified_finiquitos, -> { where(nullified: true, validated: true) }, class_name: "Finiquito"
  belongs_to :region, optional: true
  has_many   :salaries, dependent: :destroy
  has_many   :social_credits, -> { where(active: true) }, dependent: :destroy
  has_many   :vacations, -> { where(active: true) }

  # Through associations
  has_many   :active_salary_payments, -> { where(nullified: false, validated: true) }, through: :salaries, class_name: "SalaryPayment"
  has_many   :salary_payments, through: :salaries, dependent: :destroy
  has_many   :social_credit_fees, through: :social_credits

  mount_uploader :photo, AvatarUploader

  before_validation -> { rut_format!(:rut) }, if: :locale_cl?

  validates_format_of :email, :with => /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, :message => "no es válido", :allow_blank => true

  validates :rut, rut_field: true, allow_blank: true, if: :locale_cl?
  validates :rut_afiliado, rut: { message: I18n.t('activerecord.errors.commons.rut') }, allow_blank: true, if: :locale_cl?
  validates :born_at, presence: true

  SEXO = %w(Masculino Femenino).freeze
  CITIZEN = %w(Chileno Extranjero).freeze

  scope :inactive_with_salary_payment_and_rut_in_period, ->(period_expense_id) do
    where("employees.active = false and employees.rut is not null and employees.rut <> ''")
      .joins(:salary_payments)
      .where(salary_payments: { payment_period_expense_id: period_expense_id })
  end

  def self.SEXO() SEXO.map { |e| [e,e]  } end
  def self.CITIZEN() CITIZEN.map { |e| [e,e]  } end

  def to_s
    full_name
  end

  def locale_cl?
    # se valida con el locale actual, si el super admin esta en chile no se podra crear un usuario mexicano
    ["es","es-CL"].include?(I18n.locale.to_s)
  end

  def full_name
    "#{self.first_name} #{self.father_last_name} #{self.mother_last_name}".downcase.titleize.strip
  end

  def last_names
    [father_last_name, mother_last_name].reject(&:blank?).join(' ')
  end

  def full_born_date
    I18n.l self.born_at.to_date, format: :long
  end

  def get_photo(size = :medium)
    photo? ? photo.expiring_url(60, size) : CarrierWaveHandler.default_avatar(size: size)
  rescue StandardError
    CarrierWaveHandler.default_avatar(size: size)
  end

  def get_age date = nil
    return nil if self.born_at.blank?

    now = date || Time.now.utc.to_date
    birthday = self.born_at
    day_diff = now.day - birthday.day
    month_diff = now.month - birthday.month - (day_diff < 0 ? 1 : 0)
    return now.year - birthday.year - (month_diff < 0 ? 1 : 0)
  end

  def get_citizenship
    self.citizenship == "Chileno" ? "Chilena" : self.foreign_citizenship
  end

  def salary_payment_for_period(period_id)
    salary_payments.select { |salary_payment| salary_payment.payment_period_expense_id == period_id && !salary_payment.nullified && salary_payment.validated }.first
  end

  def advances_amount(period_expense)
    advances.where(period_expense_id: period_expense.id).sum(:price)
  end

  def self.generate_statutory_declaration(year, community, format, certificate_number)

    generator = StatutoryDeclaration::Generator.new(year, community, format, certificate_number, Currency.uf_value)
    resultset = generator.call
    return if resultset.nil?

    community.update_certificate_number(generator.certificate_number)
    return format_to_excel(resultset, community) if format.downcase == 'xlsx'
    # Se requiere usar ";" para el formato del CSV y no enviar el último salto de línea (csv_format[0..-2])
    # Se agrega separador de línea "row_sep: '\r\n' para que sea usado por el SII con plataforma Windows
    csv_format = resultset.map {|row| row.to_csv(:col_sep => ';', row_sep: "\r\n")}.join
    return csv_format[0..-2] if csv_format
  end

  # REQUIERE DE CARGAR PREVIAMENTE LOS PROVEEDORES y medidores
  def self.search value
    params = ["name", "rut", "first_name", "father_last_name", "mother_last_name"]
    value = value.to_s.split(' ').map { |e| e.mb_chars.unicode_normalize(:nfkd).gsub(/[^.\/\-x00-\x7F]/n, '').to_s.downcase }.join(" ")
    query = ""
    params.each do |p|
      # value.each do |w|
      query += "unaccent(lower(#{p})) like '%#{value}%' or "
      # end
    end
    query = query[0..-4]
    return query
  end

  # TODO: re use used_vacation_days inside unused_vacation_days to avoid unnecesary extra SUM sql query
  def used_vacation_days
    self.vacations.sum(:days)
  end

  def unused_vacation_days
    return 0 unless start_date
    return 0 unless vacations_start_date

    vacations = Remuneration::Vacations::VacationDaysCalculator.call(start_date: vacations_start_date, employee: self)

    vacations.data[:days_to_take].to_i
  end

  def progressive_vacations_days
    Employees::ProgressiveVacations.new(employee_id: id).call
  end

  def start_date
    self.active_salary&.start_date
  end

  def vacations_start_date
    return self.active_salary&.vacations_start_date
  end

  def send_selected_salary_payments(salary_payments_ids)
    salary_payments = active_salary_payments.where(id: salary_payments_ids).joins(
      :payment_period_expense
    ).merge(PeriodExpense.order(period: :asc))
    mail_array = []
    years = salary_payments.map { |sp| sp&.payment_period_expense&.period&.year }.uniq
    years.each do |year|
      yearly_salary_payments = salary_payments.select do |sp|
        sp.payment_period_expense.period.year == year
      end
      pdf_hash = yearly_salary_payments.each_with_object({}) do |salary_payment, hash|
        payment_url = salary_payment.pdf.expiring_url(3600)
        next if payment_url.blank?

        file_name = I18n.l(salary_payment.payment_period_expense.period, format: :short_month)
        hash[file_name + '.pdf'] = payment_url
      end
      mail_array << { pdf_hash: pdf_hash, year: year.to_s }
    end
    byebug
    if salary_payments.size < 13
      mail_array = [{ pdf_hash: mail_array.map { |a| a[:pdf_hash] }.inject(&:merge), year: nil }]
    end
    mail_array.each do |mail|
      next unless mail[:pdf_hash].present?

      NotifySalaryPaymentsJob.perform_later(
        recipient: self, community: community,
        files: mail[:pdf_hash], year: mail[:year],
        _message: I18n.t(:notify_salary_payments, scope: %i[jobs])
      )
    end
  end
end
