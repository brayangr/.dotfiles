# == Schema Information
#
# Table name: salary_payments
#
#  id                                             :integer          not null, primary key
#  IUSC                                           :integer          default(0)
#  adjust_by_rounding                             :boolean          default(FALSE)
#  advance                                        :integer          default(0)
#  advance_gratifications                         :integer          default(0)
#  afc_informed_rent                              :float
#  aguinaldo                                      :integer          default(0)
#  allocation_tool_wear                           :integer          default(0)
#  anual_gratification                            :integer          default(0)
#  anual_gratifications                           :integer          default(0)
#  aporte_sustitutivo                             :float            default(0.0)
#  apv                                            :integer          default(0)
#  asignacion_familiar                            :integer          default(0)
#  asignacion_familiar_reintegro                  :integer          default(0)
#  asignacion_familiar_tramo                      :string           default("Sin Información")
#  base_salary                                    :integer          default(0)
#  bono_days                                      :integer
#  bono_responsabilidad                           :integer          default(0)
#  bonus                                          :integer          default(0)
#  caja_de_compensacion                           :string
#  carga_familiar_retroactiva                     :integer          default(0)
#  ccaf                                           :integer          default(0)
#  commision                                      :integer          default(0)
#  cotizacion_afp_dependent                       :integer          default(0)
#  cotizacion_afp_dependent_employee_suspension   :float
#  cotizacion_desahucio                           :integer          default(0)
#  cotizacion_empleador_apvc                      :integer          default(0)
#  cotizacion_obligatoria_ips                     :integer          default(0)
#  cotizacion_obligatoria_isapre                  :integer          default(0)
#  cotizacion_puesto_trabajo_pesado               :integer          default(0)
#  cotizacion_trabajador_apvc                     :integer          default(0)
#  creator_type                                   :string
#  deposito_convenido                             :integer          default(0)
#  descuento_licencia                             :integer          default(0)
#  descuentos_imponibles                          :integer          default(0)
#  dias_licencia                                  :integer          default(0)
#  discount_days                                  :integer          default(0)
#  discount_hours                                 :float            default(0.0)
#  document                                       :string
#  document_updated_at                            :datetime
#  employee_protection_law                        :boolean          default(FALSE)
#  employee_suspension_input_amount               :float
#  empresa_sis                                    :integer          default(0)
#  empresa_sis_employee_suspension                :float
#  extra_hour                                     :float            default(0.0)
#  extra_hour_2                                   :float            default(0.0)
#  extra_hour_3                                   :float            default(0.0)
#  haberes_no_imp_comunidad                       :integer          default(0)
#  health_quote_pending                           :float            default(0.0)
#  home_office                                    :integer          default(0)
#  imponible_afp                                  :integer          default(0)
#  imponible_ccaf                                 :integer
#  imponible_cesantia                             :integer          default(0)
#  imponible_ips                                  :integer          default(0)
#  imponible_isapre                               :integer
#  imponible_mutual                               :integer          default(0)
#  invalid_number_of_loads                        :integer          default(0)
#  isl                                            :integer          default(0)
#  legal_holds                                    :integer          default(0)
#  library_response                               :text
#  lost_cash_allocation                           :integer          default(0)
#  lunch_benefit                                  :integer          default(0)
#  mothernal_number_of_loads                      :integer          default(0)
#  mutual                                         :float            default(0.0)
#  nullified                                      :boolean          default(FALSE)
#  nullified_at                                   :datetime
#  nullified_by                                   :integer
#  nullifier_type                                 :string
#  number_of_loads                                :integer          default(0)
#  nursery                                        :integer          default(0)
#  original_salary_amount_to_pay                  :float            default(0.0)
#  otros_bonos_imponible                          :integer          default(0)
#  otros_costos_empresa                           :integer          default(0)
#  payment_extra_hours                            :integer          default(0)
#  payment_extra_hours_2                          :integer          default(0)
#  payment_extra_hours_3                          :integer          default(0)
#  payment_special_bonus                          :integer          default(0)
#  pdf                                            :string
#  pdf_updated_at                                 :datetime
#  pdf_value                                      :text
#  protection_law_code                            :integer
#  reduction_percentage                           :integer          default(0)
#  refund                                         :integer          default(0)
#  renta_imponible_sustitutiva                    :integer          default(0)
#  result_adicional_salud                         :integer          default(0)
#  result_adicional_salud_employee_suspension     :float
#  result_apv                                     :integer          default(0)
#  result_bonus                                   :integer          default(0)
#  result_disc_missed_days                        :integer          default(0)
#  result_disc_missed_hours                       :integer          default(0)
#  result_missed_days                             :float            default(0.0)
#  result_worked_days                             :float            default(0.0)
#  seguro_cesantia_empleador                      :integer          default(0)
#  seguro_cesantia_empleador_employee_suspension  :float
#  seguro_cesantia_trabajador                     :integer          default(0)
#  seguro_cesantia_trabajador_employee_suspension :float
#  sis                                            :integer          default(0)
#  special_bonus                                  :integer          default(0)
#  spouse                                         :boolean          default(FALSE)
#  spouse_capitalizacion_voluntaria               :integer          default(0)
#  spouse_periods_number                          :integer          default(0)
#  spouse_voluntary_amount                        :integer          default(0)
#  subsidio_trabajador_joven                      :boolean          default(FALSE)
#  suspension_or_reduction_days                   :integer          default(0)
#  tipo_apv                                       :integer          default(1)
#  total_discount                                 :integer          default(0)
#  total_discount_2                               :integer          default(0)
#  total_haberes                                  :integer          default(0)
#  total_imponible                                :integer          default(0)
#  total_imponible_desahucio                      :integer          default(0)
#  total_liquido                                  :integer          default(0)
#  total_liquido_a_pagar                          :integer          default(0)
#  transportation_benefit                         :integer          default(0)
#  ultimo_total_imponible_sin_licencia            :integer          default(0)
#  union_fee                                      :integer          default(0)
#  union_pay                                      :integer          default(0)
#  updater_type                                   :string
#  validated                                      :boolean          default(FALSE)
#  viaticum                                       :integer          default(0)
#  worked_days                                    :integer          default(0)
#  created_at                                     :datetime         not null
#  updated_at                                     :datetime         not null
#  aliquot_id                                     :integer          default(0)
#  creator_id                                     :bigint
#  nullifier_id                                   :bigint
#  payment_period_expense_id                      :integer
#  period_expense_id                              :integer
#  salary_id                                      :integer
#  service_billing_id                             :integer
#  updater_id                                     :bigint
#
# Indexes
#
#  index_salary_payments_on_creator             (creator_type,creator_id)
#  index_salary_payments_on_nullifier           (nullifier_type,nullifier_id)
#  index_salary_payments_on_period_expense_id   (period_expense_id)
#  index_salary_payments_on_salary_id           (salary_id)
#  index_salary_payments_on_service_billing_id  (service_billing_id)
#  index_salary_payments_on_updater             (updater_type,updater_id)
#
require 'nokogiri'

class SalaryPayment < ApplicationRecord
  include AttachmentSaver
  include CalculateSalary
  include Utils
  include Formatter
  include CommunityTransactionModule
  include AttachmentTimerUpdater
  include Trackable

  belongs_to :aliquot, optional: true
  belongs_to :payment_period_expense, foreign_key: :payment_period_expense_id, class_name: 'PeriodExpense', optional: true
  belongs_to :period_expense, optional: true
  belongs_to :salary, optional: true, touch: true
  has_many   :salary_additional_infos, dependent: :destroy
  belongs_to :service_billing, dependent: :destroy, optional: true

  # Through associations
  has_one    :community, through: :payment_period_expense
  has_one    :employee, through: :salary

  attr_accessor :use_last_previred_data

  mount_uploader :document, DocumentationUploader
  mount_uploader :pdf, SingularizedPdfUploader

  accepts_nested_attributes_for :salary

  validates :dias_licencia, :discount_days, :discount_hours, :payment_extra_hours, :payment_extra_hours_2, :payment_extra_hours_3, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_hours, numericality: { less_than_or_equal_to: 360 }
  validates :suspension_or_reduction_days, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 30 }, if: proc { |x| x.employee_protection_law }
  validates :reduction_percentage, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 50 }, if: proc { |x| x.employee_protection_law && x.protection_law_code == 'reduccion_jornada_laboral' }
  validates :reduction_percentage, numericality: { equal_to: 0 }, if: proc { |x| x.employee_protection_law && x.protection_law_code != 'reduccion_jornada_laboral' }
  validates :afc_informed_rent,    numericality: { greater_than: 0 }, if: proc { |x| x.employee_protection_law && x.protection_law_code != 'reduccion_jornada_laboral' }
  validates :protection_law_code,  presence: true, if: proc { |x| x.employee_protection_law }
  validate :check_discount_days
  validate :check_extra_hours, unless: proc { |sp| sp.id.present? }
  validate :validate_no_closed_period, unless: -> { changed_attributes.key?(:document_cw) && changed_attributes.to_a.one? }
  validate :not_previous_the_initial_month
  validate :unique_active_payment_period
  validate :apvi_set
  validate :apvc_set
  validate :no_salary_payment_on_same_period

  after_save :request_calculate
  before_destroy :request_calculate
  before_destroy :destroy_community_transaction

  scope :not_nullified, -> { where(nullified: false) }
  scope :valid_and_not_nullified, -> { not_nullified.where(validated: true) }

  APVI_ATTRIBUTE_NAMES = %i[apv deposito_convenido].freeze
  APVC_ATTRIBUTE_NAMES = %i[cotizacion_empleador_apvc cotizacion_trabajador_apvc].freeze
  FONASA_LAW_CHANGE_DATE = Date.new(2023, 1)

  enum protection_law_code: { suspension_acto_autoridad: 0, suspension_pacto: 1, reduccion_jornada_laboral: 2 }

  def apvi_set
    APVI_ATTRIBUTE_NAMES.each do |attribute|
      next unless !read_attribute(attribute).to_i.zero? && salary.institucion_apvi == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS
      errors.add(attribute, :not_set)
    end
  end

  def apvc_set
    APVC_ATTRIBUTE_NAMES.each do |attribute|
      next unless !read_attribute(attribute).to_i.zero? && salary.institucion_apvc == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS
      errors.add(attribute, :not_set)
    end
  end

  def check_discount_days
    return unless payment_period_expense
    days = salary.daily_wage ? self.worked_days : 30
    return unless dias_licencia.to_i + discount_days.to_i > days.to_i
    errors.add(:base, :too_many_discount_days)
  end

  def check_extra_hours
    return unless sum_extra_hours > total_worked_days * Constants::SalaryPayments::DAILY_OVERTIME_LIMIT

    errors.add(:base, :too_many_extra_hours)
  end

  def self.protection_law_code_s(protection_law_code)
    I18n.t(protection_law_code.to_s, scope: %i[activerecord attributes salary_payment protection_law_code])
  end

  def self.protection_law_codes_select_tag
    Hash[SalaryPayment.protection_law_codes.map { |k, v| [protection_law_code_s(k), k] }]
  end

  def create_service_billing(on_creation: false)
    params = build_service_billing_params
    response = if service_billing.present?
                 ServiceBillings::Updater.call(service_billing: service_billing, params: params, community: community, updater: self, update_document: false)
               else
                 ServiceBillings::Creator.call(params: params, community: community, current_user: creator)
               end
    service_billing = response.data[:service_billing]
    self.service_billing_id = service_billing.id
    service_billing.bill = pdf
    service_billing.save
    update_or_create_community_transaction if service_billing.include_in_bank_conciliation
    save
    update_column(:updated_at, self.created_at) if on_creation
  end

  def update_or_create_community_transaction
    transaction = CommunityTransaction.find_by(origin_class: service_billing.class.name, origin_id: service_billing.id)

    if transaction.present?
      CommunityTransactions::Updater.call(transaction: service_billing)
    else
      CommunityTransactions::Creator.call(transaction: service_billing)
    end
  end

  def build_service_billing_params
    sbm = []
    if self.aliquot_id.present? && self.aliquot_id != 0
      sbm.push({
        proratable_id: self.aliquot_id,
        proratable_type: Aliquot.name,
        value: 100
      })
    end
    params = {}
    params[:category] = { name: Category.community_outcome_category(community.get_setting_value('remuneration_service_billing_categories_base'), community.id), sub_name: (community.get_setting_value('remuneration_service_billing_categories') == 0) ? SalaryPayment.model_name.human : employee.to_s.titleize }
    # Ver si existe un proveedor que ya esté relacionado con este empleado
    possible_related_employee = community.suppliers.find_by(rut: employee.rut, name: employee.to_s, active: true)
    # Si sí existe al menos uno (idealmente debería ser sólo un proveedor), asignarle el id a los parámetros. Si no, no asignarlo
    params[:supplier] = {id: possible_related_employee&.id, name: employee.to_s, rut: employee.rut }
    params[:service_billing] = {
      name: "#{I18n.t('activerecord.models.salary_payment.one')} de #{self.payment_period_expense}",
      price: self.total_liquido_a_pagar,
      service_billing_meters: sbm,
      document_type: 3,
      payment_type: ServiceBilling.PAYMENTS_TYPE.to_h[employee.active_salary&.payment_type],
      notes: "Egreso generado automáticamente en el sistema.",
      include_in_bank_conciliation: (self.community.get_setting_value('include_remuneration_in_bank_reconciliation').zero?).to_s,
      paid_at: Time.now.to_date
    }

    # Send previous period_expense because ServiceBilling#full_create uses next period
    show_in_next_period = community.get_setting_value('show_information_in_the_next_period') == 1
    period_expense = show_in_next_period ? self.period_expense.get_last.first : self.period_expense

    params[:year]  = period_expense.period.year
    params[:month] = period_expense.period.month
    params[:salary_payment_force] = true
    ActionController::Parameters.new(params)
  end


  def self.create_non_created_service_billings period_expense
    period_expense.salary_payments.each do |salary_payment|
      unless salary_payment.service_billing.present?
        CreateSalaryPaymentServiceBillingJob.perform_later(salary_payment_id: salary_payment.id, _message: "Regenerando egreso para #{salary_payment.employee}")
      end
    end
    period_expense.advances.each do |advance|
      unless advance.service_billing.present?
        CreateAdvanceServiceBillingJob.perform_later(advance_id: advance.id, _message: "Regenerando egreso de avance para #{advance.employee}")
      end
    end
  end

  def get_employee_law_code_number
    case self.protection_law_code
    when 'suspension_acto_autoridad'
      return 13
    when 'suspension_pacto'
      return 14
    when 'reduccion_jornada_laboral'
      return 15
    end
  end

  def protection_law_code_is_13_or_14?
    if self.employee_protection_law
      return self.protection_law_code == 'suspension_acto_autoridad' || self.protection_law_code == 'suspension_pacto'
    end
    return false
  end

  def get_result_adicional_salud
    if self.employee_protection_law
      return 0 if !self.total_liquido.positive? || self.total_liquido.zero?
      return 0 if self.suspension_or_reduction_days == 30
    end
    return self.result_adicional_salud
  end

  def nullify_service_billing current_user
    return true unless self.service_billing.present?
    self.service_billing.nullify(current_user)
  end


  APV_TYPE = [I18n.t('views.remunerations.salary_payments.apv_type.a'),
              I18n.t('views.remunerations.salary_payments.apv_type.b')
              ]

  def get_tipo_apv
    self.tipo_apv == 0 ? "TipoA" : "TipoB"
  end

  def self.APV_TYPE() APV_TYPE.each_with_index.map { |e,index| [e,index]  }end

  def has_document?
    document.present?
  end

  def get_document(size = :medium)
    document.present? ? document.expiring_url(60) : ''
  rescue StandardError
    ''
  end

  def request_calculate
    self.period_expense.set_request_calculate if self.period_expense.present?
  end

  def nullify!(current_date, from_service_billing = false, current_user)
    sp_saved, ct_destroyed, sb_nullified = [false] * 3
    ActiveRecord::Base.transaction do
      assign_attributes(nullified: true, nullified_at: current_date, nullifier: current_user)
      sp_saved = self.save
      social_credit = salary.employee.social_credit_fees.where("social_credit_fees.period_expense_id = ?", self.payment_period_expense_id )
      social_credit.update_all(employeed_paid: false) if social_credit.any?
      # ANULAR TRANSACCION COMUNIDAD
      ct_destroyed = self.period_expense ? self.destroy_community_transaction : true #TODELETE
      sb_nullified = !from_service_billing && self.nullify_service_billing(current_user)
      raise ActiveRecord::Rollback unless sp_saved && ct_destroyed && sb_nullified
    end
    return false unless sp_saved && ct_destroyed && sb_nullified

    if self.payment_period_expense.present?
      community_id = self.payment_period_expense.community_id
      comment = I18n.t(:grouping, scope: %i[messages notices salary_payments])
      unless Delayed::Job.where(comments: comment, community_id: community_id).count >= 2
        CollectAllPdfSalaryPaymentsJob.perform_later(_community_id: community_id, period_expense_id: payment_period_expense.id, _message: comment)
      end
    end
    true
  end

  def generate_pdf(run_validations: true)
    save_pdf_in_amazon(run_validations: run_validations)

    community_id = self.period_expense&.community_id || self.payment_period_expense.community_id
    comment = "Agrupando #{I18n.t('activerecord.models.salary_payment.other').downcase}"
    unless Delayed::Job.where(comments: comment, community_id: community_id).count >= 2
      CollectAllPdfSalaryPaymentsJob.perform_later(_community_id: community_id, period_expense_id: payment_period_expense.id, _message: comment)
    end
  end

  def save_pdf_in_amazon(run_validations: true)
    service = Remuneration::SalaryPayments::PdfGenerator.call(salary_payment_id: id).data

    save_attachment(
      folder_name: 'user_temp/salary_payments/',
      path: "user_temp/salary_payments/#{service[:filename]}",
      file: service[:pdf].render,
      save_file: false
    )

    save(validate: run_validations)
  end

  def new_fonasa_distribution?
    self.payment_period_expense.period >= FONASA_LAW_CHANGE_DATE
  end

  def get_final_rounded_amount(amount)
    self.adjust_by_rounding ? Currency.rounding_rule(amount) : amount
  end

  # def work_days
  #   start = self.salary.start_date
  #   month_days = Time.days_in_month( self.period_expense.period.month, self.period_expense.period.year)

  #   #Si es el mes en curso, considerar el proporcional
  #   if Time.now.month == start.month and Time.now.year == start.year
  #     month_days = month_days -  start.day
  #   end
  #   month_days - self.discount_days
  # end

  def get_sueldo_bruto
    self.total_imponible.to_i + self.haberes_no_imp_comunidad.to_i + self.otros_costos_empresa.to_i - self.asignacion_familiar.to_i - self.refund.to_i
  end

  def get_bill_description
    "Sueldo Líquido de #{self.employee}, mes: #{self.payment_period_expense}"
  end

  def hash_bill_details employee_price
    {"ref_object_id" => self.id , "price" => employee_price.round(0), "title" => self.get_bill_description,"ref_object_class" => "SalaryPayment", "referential_price" => self.get_sueldo_bruto, "aliquot_id" => self.aliquot_id }
  end

  def get_payment_sis(employee)
    return 0 if employee.born_at.present? && employee.get_age(payment_period_expense.period) >= Constants::Remunerations::AGE_THRESHOLD

    sis + empresa_sis
  end

  def taxable_income_ips
    return total_haberes if total_haberes.positive? || salary.community.has_mutual?

    ultimo_total_imponible_sin_licencia
  end

  def self.prepare_new(employee, period_expense)
    salary_payment = employee.salary_payments.where(nullified: false, validated: false).first_or_initialize(salary_id: employee.active_salary.id)
    last_salary_payment = employee.active_salary_payments.joins(:payment_period_expense).order("period_expenses.period desc").first
    payment_date = employee.active_salary.start_date.present? ? [employee.active_salary.start_date , period_expense.period].max : period_expense.period

    if last_salary_payment.present?

      salary_payment.advance_gratifications           = last_salary_payment.advance_gratifications
      salary_payment.anual_gratifications             = last_salary_payment.anual_gratifications
      # salary_payment.viaticum                       = last_salary_payment.viaticum
      salary_payment.lost_cash_allocation             = last_salary_payment.lost_cash_allocation
      salary_payment.allocation_tool_wear             = last_salary_payment.allocation_tool_wear
      salary_payment.union_fee                        = last_salary_payment.union_fee
      salary_payment.legal_holds                      = last_salary_payment.legal_holds
      salary_payment.apv                              = employee.active_salary.institucion_apvi == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS ? 0 : last_salary_payment.apv
      salary_payment.cotizacion_empleador_apvc        = employee.active_salary.institucion_apvc == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS ? 0 : last_salary_payment.cotizacion_empleador_apvc
      salary_payment.cotizacion_trabajador_apvc       = employee.active_salary.institucion_apvc == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS ? 0 : last_salary_payment.cotizacion_trabajador_apvc
      salary_payment.bono_responsabilidad             = last_salary_payment.bono_responsabilidad
      salary_payment.spouse_voluntary_amount          = last_salary_payment.spouse_voluntary_amount
      salary_payment.spouse_periods_number            = last_salary_payment.spouse_periods_number
      salary_payment.spouse_capitalizacion_voluntaria = last_salary_payment.spouse_capitalizacion_voluntaria
      salary_payment.worked_days                      = 30
      salary_payment.aliquot_id                       = last_salary_payment.aliquot_id

      if employee.community.get_setting_value('show_information_in_the_next_period') == 1
        salary_payment.period_expense_id              = last_salary_payment.period_expense_id
      else
        salary_payment.period_expense_id              = last_salary_payment.period_expense&.get_next&.first&.id
      end

      if last_salary_payment.payment_period_expense.present?
        salary_payment.payment_period_expense_id = last_salary_payment.payment_period_expense.get_next.first.id
      else
        salary_payment.payment_period_expense_id = employee.community.get_period_expense(payment_date.month, payment_date.year).id
      end

      # agregar los bonos y descuentos adicionales del último mes
      salary_payment.salary_additional_infos = last_salary_payment.salary_additional_infos.map do |additional_info|
        SalaryAdditionalInfo.new(
          name: additional_info.name,
          discount: additional_info.discount,
          value: additional_info.value,
          checked: additional_info.checked,
          post_tax: additional_info.post_tax
        )
      end

    else
      # Se toma el mes en curso en caso de no tener liquidación anterior
      salary_payment.period_expense_id         = period_expense.id
      salary_payment.payment_period_expense_id = employee.community.get_period_expense(payment_date.month, payment_date.year).id
    end

    #último total imponible sin licencia
    liquidacion_sin_licencia = employee.salary_payments.where(nullified:false , validated: true, dias_licencia: 0).joins(:payment_period_expense).order("period_expenses.period desc").first

    ultimo_total_imponible_sin_licencia = liquidacion_sin_licencia.present? ? liquidacion_sin_licencia.total_imponible : 0
    salary_payment.ultimo_total_imponible_sin_licencia = ultimo_total_imponible_sin_licencia


    #Considerar el pago de acuerdo al mes de la liquidación Adelantos y creditos sociales
    salary_payment.advance = employee.advances.where(period_expense_id:  salary_payment.payment_period_expense_id).sum(:price)
    salary_payment.ccaf = employee.social_credit_fees.where(period_expense_id: salary_payment.payment_period_expense_id ).sum(:price)

    return salary_payment

  end

  #################
  ##### EXCEL #####
  #################
  def self.generate_excel(salary_payments, current_user, employee, community)
    show_in_next_period = community.get_setting_value('show_information_in_the_next_period') == 1
    document = []
    sp_sheet = {}
    sp_sheet[:name] = employee.to_s
    sp_sheet[:title] = ['', "#{I18n.t('activerecord.models.salary_payment.other')} de sueldo #{employee}"]
    sp_sheet[:sub_title] = ['', community.to_s]
    sp_sheet[:body] = []

    # Header
    sp_header = ['']
    sp_style = ['']
    if current_user.admin?
      sp_header.push('ID')
      sp_style.push('')
    end
    sp_header.push('Fecha de creación', I18n.t('views.common_expenses.one'), 'Período', 'Bruto', 'Imponible', 'Líquido', 'Líquido a pagar')
    sp_style.push('date', '', '', 'price', 'price', 'price', 'price')
    sp_sheet[:header] = sp_header
    sp_sheet[:style]  = sp_style

    # Rows
    sp_row = ['']
    salary_payments.each do |salary_payment|
      # TODO: Fix N+1
      period_expense = show_in_next_period ? salary_payment.period_expense.get_last.first : salary_payment.period_expense
      sp_row << salary_payment.id if current_user.admin?
      sp_row.push(salary_payment.created_at.to_date, period_expense, salary_payment.payment_period_expense, salary_payment.get_sueldo_bruto, salary_payment.total_imponible, salary_payment.total_liquido, salary_payment.total_liquido_a_pagar)

      sp_sheet[:body].append({
        content: sp_row,
        style: { alternated: true }
      })
      sp_row = ['']
    end

    document.push(sp_sheet)
    format_to_excel(document, community)
  end

  def safe_library_response
    begin
     JSON.pretty_generate(JSON.parse(self.library_response))
    rescue
     self.library_response
    end
  end

  # SOLO DE RECAMBIO
  def self.to_amazon
    SalaryPayment.where(pdf: nil).order('created_at desc').all.each do |b|
      if b.pdf_value.present?
        SaveSalaryPaymentPdfInAmazonJob.perform_later(salary_payment_id: b.id, content: b.pdf_value, _message: "#{I18n.t('activerecord.models.salary_payment.one')} #{b.id}, período: #{b.period_expense_id}")
      end
    end
  end

  # Validar qe solo puede haber una liquidación de sueldo activa en cada payment_period
  def unique_active_payment_period
    payments = SalaryPayment.where(validated: true, nullified: false, payment_period_expense: self.payment_period_expense, salary: self.salary)
                            .where.not(id: self.id)
    if payments.exists?
      errors.add(:payment_period_expense, I18n.t('messages.errors.salary_payments.no_double_salary_payment_for_payment_period'))
      return false
    end
    true
  end

  def validate_no_closed_period
    if period_expense.present?
      can_create_in_period = community.get_setting_value('incomes_and_outcomes_in_closed_periods') == 1 || !period_expense.common_expense_generated
      # Only allow document to be changed.
      if period_expense && !can_create_in_period && changes_to_save.keys != ['document']
        errors.add(:period_expense, I18n.t('messages.errors.salary_payments.no_salary_payment_in_closed_period_expense'))
        return false
      end
    end
    true
  end

  def no_salary_payment_on_same_period
    return unless self.employee.present? && self.payment_period_expense.present?
    map_period_expenses = PeriodExpense.joins(salary_payments: :salary).where(salaries: {employee_id: self.employee.id}, salary_payments: {nullified: true}).where.not(salary_payments: {id: self.id}).map{|pe| [pe.period.month, pe.period.year]}.uniq
    return unless map_period_expenses.include? [self.payment_period_expense.period.month, self.payment_period_expense.period.year]
    errors.add(:period_expense, I18n.t('activerecord.errors.models.salary_payment.attributes.payment_period_expense.already_generated'))
  end

  def send_voucher_to_employee
    return unless employee.present?

    period_date = I18n.l(payment_period_expense.period, format: :short_month_clean)

    NotifyUserWithPdfJob.perform_later(
      community:     community,
      content:       period_date,
      file_name:     I18n.t('mailers.notify_salary_payment.file'),
      object:        self,
      origin_mail:   community.contact_email,
      recipient:     employee,
      template:      'notify_employee_salary_payment_summary_by_period',
      title:         I18n.t('mailers.notify_salary_payment.title', period_date: period_date, community_name: community.name),
      _community_id: community.id,
      _message:      I18n.t(:notify_user_with_pdf_as_attachment, scope: %i[jobs])
    )
  end

  def not_previous_the_initial_month
    initial_period = self.employee.community.period_expenses.where(initial_setup: true).order(period: :desc).first
    byebug
    return if self.payment_period_expense.period >= initial_period.period
    errors.add(:payment_period_expense, :cannot_be_previous_to_initial_month)
  end

  def sum_extra_hours
    extra_hour.to_f + extra_hour_2.to_f + extra_hour_3.to_f
  end

  def total_worked_days
    if salary.daily_wage
      worked_days.to_i
    elsif library_response.present?
      JSON.parse(library_response).dig('result', 'total_worked_days').to_i
    else
      30
    end
  end
end
