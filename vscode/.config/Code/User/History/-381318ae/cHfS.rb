# == Schema Information
#
# Table name: salaries
#
#  id                                          :integer          not null, primary key
#  account_number                              :string           default("")
#  account_rut                                 :string           default("Cuenta Corriente")
#  account_type                                :string           default("Cuenta Corriente")
#  active                                      :boolean          default(TRUE)
#  additional_hour_price                       :float            default(50.0)
#  additional_hour_price_2                     :float            default(0.0)
#  additional_hour_price_3                     :float            default(0.0)
#  afc_start_date                              :date
#  afp                                         :string
#  afp_second_account                          :integer          default(0)
#  age                                         :string           default("Entre 18 y 65 años")
#  asignacion_familiar_tramo                   :string           default("D")
#  bank                                        :string           default("")
#  base_price                                  :integer          default(0)
#  bono_diario_colacion_movilizacion           :boolean          default(FALSE)
#  ccaf2                                       :string           default("Sin CCAF")
#  ccaf2_amount                                :integer          default(0)
#  comments                                    :text
#  contract_file                               :string
#  contract_file_updated_at                    :datetime
#  contract_type                               :string           default("Indefinido")
#  cotizacion_ccaf_no_isapre                   :integer          default(0)
#  daily_wage                                  :boolean          default(FALSE)
#  days_per_week                               :integer          default(5)
#  descuento_cargas_familiares_ccaf            :integer          default(0)
#  descuento_dental_ccaf                       :integer          default(0)
#  descuento_leasing_ccaf                      :integer          default(0)
#  descuento_seguro_de_vida_ccaf               :integer          default(0)
#  employee_type                               :string
#  ex_caja_regimen                             :string
#  ex_caja_regimen_desahucio                   :string
#  has_afp                                     :boolean          default(TRUE)
#  has_ips                                     :boolean          default(FALSE)
#  has_isapre                                  :boolean          default(TRUE)
#  has_seguro_cesantia                         :boolean          default(TRUE)
#  institucion_apvc                            :string
#  institucion_apvi                            :string
#  institucion_apvi2                           :string
#  invalid_number_of_loads                     :integer          default(0)
#  isapre                                      :string           default("Fonasa")
#  isapre_codelco                              :string
#  lunch_benefit                               :integer          default(0)
#  mothernal_number_of_loads                   :integer          default(0)
#  number_of_loads                             :integer          default(0)
#  numero_contrato_apvc                        :bigint           default(0)
#  numero_contrato_apvi                        :bigint           default(0)
#  numero_contrato_apvi2                       :bigint           default(0)
#  numero_fun                                  :bigint           default(0)
#  otros_datos_empresa                         :string
#  otros_descuentos_ccaf                       :integer          default(0)
#  pago_directo_apvc                           :boolean          default(TRUE)
#  pago_directo_apvi                           :boolean          default(TRUE)
#  pago_directo_apvi2                          :boolean          default(TRUE)
#  payment_message                             :text
#  payment_type                                :string           default("Transferencia")
#  person_with_disability                      :integer          default(0)
#  place_of_payment                            :string
#  plan_isapre                                 :float
#  plan_isapre_en_uf                           :boolean          default(TRUE)
#  porcentaje_cotizacion_puesto_trabajo_pesado :float            default(0.0)
#  prior_quotations                            :integer          default(0)
#  puesto_trabajo_pesado                       :string
#  rut_pagadora_subsidio                       :string
#  spouse_afp                                  :string
#  start_date                                  :datetime
#  subsidio_trabajador_joven                   :boolean          default(FALSE)
#  subsidy_young_worker                        :boolean          default(FALSE)
#  tasa_cotizacion_desahucio_ex_caja           :float            default(0.0)
#  tasa_cotizacion_ex_caja                     :float            default(0.0)
#  tasa_pactada_sustitutiva                    :float            default(0.0)
#  tipo_empleado                               :integer          default(0)
#  transportation_benefit                      :integer          default(0)
#  vacations_start_date                        :datetime
#  week_hours                                  :float            default(45.0)
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  employee_id                                 :integer
#
# Indexes
#
#  index_salaries_on_employee_id  (employee_id)
#
class Salary < ApplicationRecord
  include AttachmentTimerUpdater

  has_many   :active_salary_payments, -> { where(nullified: false, validated: true) }, class_name: "SalaryPayment"
  belongs_to :employee, optional: true
  has_one    :last_active_salary_payment, -> { where(nullified: false, validated: true).includes(:payment_period_expense).order("period_expenses.period desc").limit(1)}, class_name: "SalaryPayment"
  has_many   :salary_payments, dependent: :destroy
  has_many   :salary_payment_drafts

  # Through associations
  has_one    :community, through: :employee

  # validates_numericality_of :afp_second_account, :numero_contrato_apvi, :numero_contrato_apvc, :numero_fun, :descuento_dental_ccaf, :descuento_leasing_ccaf, :descuento_seguro_de_vida_ccaf, :otros_descuentos_ccaf, :cotizacion_ccaf_no_isapre, :descuento_cargas_familiares_ccaf, greater_than_or_equal_to: 0

  # validates_numericality_of :porcentaje_cotizacion_puesto_trabajo_pesado, :tasa_cotizacion_ex_caja, :tasa_cotizacion_desahucio_ex_caja, greater_than_or_equal_to: 0.0

  validates_presence_of %i[week_hours start_date]
  validates_presence_of :days_per_week

  validates :account_rut, rut: { message: I18n.t('activerecord.errors.commons.rut') }, allow_blank: true
  validates :rut_pagadora_subsidio, rut: { message: I18n.t('activerecord.errors.commons.rut') }, allow_blank: true
  validate :afc_start_date_after_employee_born, :afc_start_date_not_in_future, :vacations_start_date_earlier_than_start_date
  validates :vacations_start_date, presence: true

  before_create :default_payment_message
  before_save :parse_payment_message

  CONTRACTS_TYPE = ["Indefinido", "A plazo fijo", "Obra"]
  EMPLOYEE_TYPE_OPTIONS = %w[Dependiente Independiente]
  AFP = ["No tiene", "Cuprum", "Habitat", "ProVida", "PlanVital", "Capital", "Modelo", "Uno"]
  REGIMEN_PREV = %w[AFP INP SIP]
  PAYMENTS_TYPE = ['Cheque', 'Efectivo', 'Transferencia', 'Depósito', 'Vale vista']
  ACCOUNT_TYPE = ["Cuenta corriente","Cuenta rut","Cuenta vista","Cuenta ahorro"]
  ASIGNACION_FAMILIAR_TRAMOS = [ "A", "B", "C", "D" ]
  OBLIGATORY_AFC_START_DATE = Date.new(2002,10,02)
  CODELCO_LRE = ['Chuquicamata', 'Fusat', 'Rio Blanco','Lorenzo'].freeze
  DISABILITY_PENSION_LRE = [
    ['No', 0],
    ['Discapacidad Certificada por la Compin', 1],
    ['Asignatario Pensión por Invalidez Total', 2],
    ['Pensionado con Invalidez Parcial', 3]].freeze

  # ASIGNACION_FAMILIAR_TRAMOS = [ "A","B","C","D", "Sin Información"]

  mount_uploader :contract_file, DocumentationUploader

  def get_age
    now = Time.now.utc.to_date
    birthday = self.employee.born_at
    now.year - birthday.year - (birthday.to_date.change(:year => now.year) > now ? 1 : 0)
  end

  def afc_start_date_after_employee_born
    if self.employee.present? && self.afc_start_date.present?
      self.errors.add(:afc_start_date, :earlier_than_employees_birthdate) if TimeZone.get_local_time(community: self.community, date_time: self.afc_start_date) < TimeZone.get_local_time(community: self.community, date_time: employee.born_at)
    end
  end

  def afc_start_date_not_in_future
    self.errors.add(:afc_start_date, :start_in_future) if self.afc_start_date.present? && TimeZone.get_local_time(community: self.community, date_time: self.afc_start_date) > TimeZone.get_local_time(community: self.community, date_time: Time.now)
  end

  def vacations_start_date_earlier_than_start_date
    if self.vacations_start_date.present?
      self.errors.add(:vacations_start_date, :equal_than_employees_start_date) if self.vacations_start_date < self.start_date
    else
      self.errors.add(:vacations_start_date, :blank)
    end
  end

  def self.CONTRACTS_TYPE() CONTRACTS_TYPE.map { |e| [e,e]  } end
  def self.EMPLOYEE_TYPE_OPTIONS() EMPLOYEE_TYPE_OPTIONS.map { |e| [e,e]  } end
  def self.AFP() AFP.map { |e| [e,e]  } end
  def self.ISAPRE() Constants::Isapre::ISAPRE.keys.map { |e| [e,e] } end
  def self.PAYMENTS_TYPE() PAYMENTS_TYPE.map { |e| [e,e]  } end
  def self.ACCOUNT_TYPE() ACCOUNT_TYPE.map { |e| [e,e]  } end
  def self.ASIGNACION_FAMILIAR_TRAMOS() ASIGNACION_FAMILIAR_TRAMOS.each.map { |e| [e,e]  } end

  def self.codelco
    CODELCO_LRE.map { |c| [c, c] }
  end

  def self.disability_pension
    DISABILITY_PENSION_LRE
  end

  def self.afp_options() [["Tiene AFP",true], ["No cotiza AFP",false] ] end
  def self.isapre_options() [["Sí",true], ["No",false] ] end
  def self.seguro_cesantia_options() [["Tiene Seguro de cesantía",true], ["No tiene seguro de cesantía",false ]] end
  def self.codigo_empleado_options() [["Activo (No Pensionado)", 0], ["Pensionado y cotiza", 1], ["Pensionado y no cotiza", 2], ["Activo > 65 años (nunca pensionado)", 3]] end

  def less_than_11_years date
    if self.afc_start_date.present? && self.start_date < OBLIGATORY_AFC_START_DATE
      (self.afc_start_date + 11.years) > date
    else
      (self.start_date + 11.years) > date
    end
  end

  def get_payment_description(home = false)
    desc = home ? "Medio de pago: #{payment_type}." : " El medio de pago fue: #{payment_type}."
    if %w[Transferencia Depósito].include?(payment_type)
      desc += " A la #{account_type.to_s.downcase}, número: #{account_number} del banco: \"#{bank}\", asociada al rut: #{account_rut.rutify}."
    end

    desc
  end

  def has_contract_file?
    contract_file.present?
  end

  def regimen_previsional
    (self.has_ips ? "INP" : "AFP")
  end

  def self.get_afp_code afp
    case afp
    when "Cuprum"
      return "03"
    when "Habitat"
      return "05"
    when "ProVida"
      return "08"
    when "PlanVital"
      return "29"
    when "Capital"
      return "33"
    when "Modelo"
      return "34"
    when "Uno"
      return "35"
    else
      return "00"
    end
  end

  def get_isapre_code
    Constants::Isapre::ISAPRE.merge(Constants::Isapre::ISAPRE_ALTERNATE_NAMES).fetch(self.isapre, "")
  end

  def get_moneda_isapre
    self.plan_isapre_en_uf ? "2" : "1"
  end

  def self.get_codigo_caja_ex_regimen
    return{
      "No pertenece al IPS" => "0000",
      "Bancaria - Régimen 1" => "0201",
      "Bancaria - Régimen 2" => "0202",
      "Bancaria - Régimen 3" => "0203",
      "Bancaria - Régimen 14" => "0214",
      "Bancaria - Régimen 21" => "0221",
      "Bancaria - Régimen 34" => "0234",
      "Caja de Previsión de Gildemeister - Régimen 1" => "2201",
      "Caja de Previsión de Gildemeister - Régimen 2" => "2202",
      "Caja de Previsión Social de los EE - Régimen 1" => "1601",
      "Caja de Previsión Social de los EE - Régimen 2" => "1602",
      "Caja Ferro - Régimen 2" => "1202",
      "Caja Ferro - Régimen 3" => "1203",
      "Caja Ferro - Régimen 4" => "1204",
      "Caja Ferro - Régimen 5" => "1205",
      "Caja Ferro - Régimen 7" => "1207",
      "Canaempu: Periodistas - Régimen 1" => "1401",
      "Canaempu: Periodistas - Régimen 2" => "1402",
      "Canaempu: Periodistas - Régimen 3" => "1403",
      "Canaempu: Periodistas - Régimen 4" => "1404",
      "Canaempu: Periodistas - Régimen 5" => "1405",
      "Canaempu: Periodistas - Régimen 6" => "1406",
      "Canaempu: Periodistas - Régimen 7" => "1407",
      "Canaempu: Periodistas - Régimen 8" => "1408",
      "Canaempu: Periodistas - Régimen 11" => "1411",
      "Canaempu: Periodistas - Régimen 12" => "1412",
      "Canaempu: Periodistas - Régimen 13" => "1413",
      "Canaempu: Periodistas - Régimen 14" => "1414",
      "Canaempu: Periodistas - Régimen 15" => "1415",
      "Canaempu: Periodistas - Régimen 16" => "1416",
      "Canaempu: Periodistas - Régimen 17" => "1417",
      "Canaempu: Periodistas - Régimen 18" => "1418",
      "Canaempu: Periodistas - Régimen 21" => "1421",
      "Canaempu: Periodistas - Régimen 22" => "1422",
      "Canaempu: Periodistas - Régimen 23" => "1423",
      "Canaempu: Periodistas - Régimen 24" => "1424",
      "Canaempu: Periodistas - Régimen 25" => "1425",
      "Canaempu: Periodistas - Régimen 26" => "1426",
      "Canaempu: Periodistas - Régimen 31" => "1431",
      "Canaempu: Periodistas - Régimen 32" => "1432",
      "Canaempu: Periodistas - Régimen 33" => "1433",
      "Canaempu: Periodistas - Régimen 34" => "1434",
      "Canaempu: Públicos - Régimen 1" => "1301",
      "Canaempu: Públicos - Régimen 2" => "1302",
      "Canaempu: Públicos - Régimen 3" => "1303",
      "Canaempu: Públicos - Régimen 5" => "1305",
      "Canaempu: Públicos - Régimen 6" => "1306",
      "Canaempu: Públicos - Régimen 8" => "1308",
      "Canaempu: Públicos - Régimen 9" => "1309",
      "Canaempu: Públicos - Régimen 10" => "1310",
      "Canaempu: Públicos - Régimen 11" => "1311",
      "Canaempu: Públicos - Régimen 12" => "1312",
      "Canaempu: Públicos - Régimen 21" => "1321",
      "Canaempu: Públicos - Régimen 22" => "1322",
      "Canaempu: Públicos - Régimen 23" => "1323",
      "Canaempu: Públicos - Régimen 25" => "1325",
      "Canaempu: Públicos - Régimen 26" => "1326",
      "Canaempu: Públicos - Régimen 28" => "1328",
      "Canaempu: Públicos - Régimen 29" => "1329",
      "Canaempu: Públicos - Régimen 30" => "1330",
      "Canaempu: Públicos - Régimen 31" => "1331",
      "Canaempu: Públicos - Régimen 32" => "1332",
      "Canaempu: Públicos - Régimen 38" => "1338",
      "Caprebech - Régimen 1" => "0501",
      "Caprebech - Régimen 3" => "0503",
      "Caprebech - Régimen 14" => "0514",
      "Caprebech - Régimen 21" => "0521",
      "Caprebech - Régimen 34" => "0534",
      "Capremer - Régimen 1" => "0601",
      "Capremer - Régimen 2" => "0602",
      "Capremer - Régimen 3" => "0603",
      "Capremer - Régimen 4" => "0604",
      "Capremer - Régimen 5" => "0605",
      "Capremer - Régimen 6" => "0606",
      "Capremer - Régimen 8" => "0608",
      "Copremusa EE - Régimen 1" => "1501",
      "Copremusa EE - Régimen 2" => "1502",
      "Copremusa EE - Régimen 3" => "1503",
      "Diomp - Régimen 1" => "1901",
      "EE Municipales de la Republica - Régimen 1" => "1701",
      "EE Municipales de la Republica - Régimen 2" => "1702",
      "EE Municipales de la Republica - Régimen 3" => "1703",
      "EE Municipales de la Republica - Régimen 4" => "1704",
      "EE Salitre - Régimen 1" => "2001",
      "EE Salitre - Régimen 2" => "2002",
      "Empart - Régimen 1" => "0101",
      "Empart - Régimen 2" => "0102",
      "Empart - Régimen 3" => "0103",
      "Empart - Régimen 4" => "0104",
      "Empart - Régimen 6" => "0106",
      "Empleados de Emos - Régimen 1" => "1001",
      "Hípica Nacional - Régimen 1" => "0801",
      "Hípica Nacional - Régimen 2" => "0802",
      "Hípica Nacional - Régimen 3" => "0803",
      "Hípica Nacional - Régimen 4" => "0804",
      "Mauricio, Hochschild - Régimen 1" => "2301",
      "Mauricio, Hochschild - Régimen 2" => "2302",
      "Obreros de Emos - Régimen 1" => "1101",
      "OO Municipales de la Republica - Régimen 1" => "1801",
      "OO Municipales de la Republica - Régimen 2" => "1802",
      "OO Municipales de la Republica - Régimen 3" => "1803",
      "Sección Esp.Previsión Empleados - Régimen 1" => "2101",
      "Sección Esp.Previsión Empleados - Régimen 2" => "2102",
      "Secgasco - Régimen 1" => "2401",
      "Secgasco - Régimen 2" => "2402",
      "Servicios de Seguro Social - Régimen 1" => "0901",
      "Servicios de Seguro Social - Régimen 2" => "0902",
      "Triomar - Régimen 1" => "0701",
      "Triomar - Régimen 2" => "0702",
      "Triomar - Régimen 3" => "0703",
      "Triomar - Régimen 4" => "0704"
    }
  end

  def self.get_rut_pagador_subsidio
    return {
      "Banmédica" => "96572800-7",
      "Consalud" => "96856780-2",
      "Vida Tres" => "96502530-8",
      "Colmena" => "76296619-0",
      "Isapre Cruz Blanca S.A." => "96501450-0",
      "Fonasa" => "61603000-0",
      "Chuquicamata" => "79566720-2",
      "Óptima Isapre (ex Ferrosalud)" => "96504160-5",
      "Institución de Salud Previsional Fusat Ltda." => "76334370-7",
      "Isapre Banco Estado" => "71235700-2",
      "Más Vida" => "96522500-5",
      "Río Blanco" => "89441300-k",
      "San Lorenzo Isapre Ltda." => "79906120-1",
      "Cruz del Norte" => "76521250-2",
      "Asociación Chilena de Seguridad (ACHS)" => "70360100-6",
      "Mutual de Seguridad CCHC" => "70285100-9",
      "Instituto de Seguridad del Trabajo I.S.T." => "70015580-3",
      "Instituto de Seguridad Laboral I.S.L." => "61533000-0"
    }
  end

  def self.get_codigo_caja_ex_regimen_desahucio
    return{
      "Empart, código 0101" => "0101",
      "Bancaria, código 0201" => "0201",
      "Bancaria, código 0202" => "0202",
      "Bancaria, código 0203" => "0203",
      "Caprebech, código 0501" => "0501",
      "Caprebech, código 0502" => "0502",
      "Caprebech, código 0503" => "0503",
      "Capremer, código 0601" => "0601",
      "Capremer, código 0603" => "0603",
      "Servicios de Seguro Social, código 0902" => "0902",
      "Caja Ferro, código 1204" => "1204",
      "Canaempu: Públicos, código 1303" => "1303",
      "Canaempu: Públicos, código 1311" => "1311",
      "Canaempu: Públicos, código 1343" => "1343",
      "Canaempu: Públicos, código 1363" => "1363",
      "Canaempu: Periodistas, código 1401" => "1401",
      "Canaempu: Periodistas, código 1402" => "1402",
      "Canaempu: Periodistas, código 1406" => "1406",
      "Copremusa EE, código 1501" => "1501",
      "Copremusa EE, código 1503" => "1503",
      "Caja de Previsión Social de los EE, código 1601" => "1601",
      "Caja de Previsión Social de los EE, código 1602" => "1602",
      "EE Municipales de la República, código 1701" => "1701",
      "Diomp, código 1901" => "1901"
    }
  end

  def self.get_apv_code
    return {
      "No Cotiza A.P.V." => "000",
      "Cuprum" => "003",
      "Habitat" => "005",
      "Provida" => "008",
      "Planvital" => "029",
      "Capital" => "033",
      "Modelo" => "034",
      "Uno" => "035",
      #Institución Autorizada APV - APVC : Cias Seguros de Vida
      "ABN AMRO (CHILE) SEGUROS DE VIDA S.A." => "100",
      "AGF ALLIANZ CHILE COMPAÑIA DE SEGUROS VIDA S.A" => "101",
      "SANTANDER SEGUROS DE VIDA S.A." => "102",
      "BCI SEGUROS VIDA S.A." => "103",
      "BANCHILE SEGUROS DE VIDA S.A." => "104",
      "BBVA SEGUROS DE VIDA S.A." => "105",
      "BICE VIDA COMPAÑIA DE SEGUROS S.A." => "106",
      "CHILENA CONSOLIDADA SEGUROS DE VIDA S.A." => "107",
      "CIGNA COMPAÑIA DE SEGUROS DE VIDA S.A." => "108",
      "CN LIFE, COMPAÑIA DE SEGUROS DE VIDA S.A." => "109",
      "COMPAÑIA DE SEGUROS DE VIDA CARDIF S.A." => "110",
      "CIA DE SEG. DE VIDA CONSORCIO NACIONAL DE SEG S.A." => "111",
      "COMPAÑIA DE SEGUROS DE VIDA HUELEN S.A." => "113",
      "COMPAÑIA DE SEGUROS DE VIDA VITALIS S.A." => "115",
      "COMPAÑIA DE SEGUROS CONFUTUTO S.A." => "116",
      "SEGUROS DE VIDA SURA S.A." => "118",
      "METLIFE CHILE SEGUROS DE VIDA S.A." => "121",
      "MAPFRE COMPAÑIA DE SEGUROS DE VIDA DE CHILE S.A." => "123",
      "MUTUAL DE SEGUROS DE CHILE" => "125",
      "MUTUALIDAD DE CARABINEROS" => "126",
      "MUTUALIDAD DEL EJERCITO Y AVIACION" => "127",
      "OHIO NATIONAL SEGUROS DE VIDA S.A." => "128",
      "PRINCIPAL COMPAÑIA DE SEGUROS DE VIDA CHILE S.A." => "129",
      "RENTA NACIONAL COMPAÑIA DE SEGUROS DE VIDA S.A." => "130",
      "SEGUROS DE VIDA SECURITY PREVISION S.A." => "131",
      "COMPAÑIA DE SEGUROS GENERALES PENTA-SECURITY S.A." => "134",
      "PENTA VIDA COMPAÑIA DE SEGUROS DE VIDA S.A." => "135",
      "ACE SEGUROS S.A." => "136",
      #Institución Autorizada APVI - APVC : Fondos Mutuos
      "BANDESARROLLO ADM. GENERAL DE FONDOS S.A." => "201",
      "BBVA ASSET MANAGEMENT AGF S.A." => "203",
      "BCI ASSET MANAGEMENT ADMINISTRADORA GENERAL DE FONDOS S.A." => "204",
      "BICE INVERSIONES AGF S.A." => "205",
      "BTG PACTUAL CHILE S.A. ADMINISTRADORA GENERAL DE FONDOS" => "208",
      "PRINCIPAL ADMINISTRADORA GENERAL DE FONDOS S.A." => "214",
      "SANTANDER ASSET MANAGEMENT S.A. ADM. GENERAL DE FONDOS" => "215",
      "SCOTIA SUDAMERICANO ADMINISTRADORA DE FONDOS MUTUOS S.A." => "217",
      "ADMINISTRADORA GENERAL DE FONDOS SECURITY S.A." => "218",
      "ZURICH ADMINISTRADORA GENERAL DE FONDOS S.A." => "224",
      "ITAU ADMINISTRADORA GENERAL DE FONDOS S.A." => "225",
      "BANCOESTADO S.A. ADMINISTRADORA GENERAL DE FONDOS" => "229",
      "FINTUAL ADMINISTRADORA GENERAL DE FONDOS S.A" => "237",
      "ZURICH CHILE ASSET MANAGEMENT AGF S.A." => "600",
      "LARRAIN VIAL ADMINISTRADORA GENERAL DE FONDOS S.A." => "601",
      #Institución Autorizada APVI - APVC: Corredores de Bolsa
      "LARRAIN VIAL S.A. CORREDORA DE BOLSA" => "213",
      "BANCHILE CORREDORES DE BOLSA S.A." => "222",
      "CORREDORES DE BOLSA SURA S.A." => "227",
      "BTG PACTUAL CHILE S.A. CORREDORES DE BOLSA" => "228",
      "SCOTIA SUD AMERICANO CORREDORES DE BOLSA S.A." => "231",
      "BICE INVERSIONES CORREDORES DE BOLSA S.A." => "232",
      "VALORES SECURITY S.A. CORREDORES DE BOLSA" => "234",
      "MBI CORREDORES DE BOLSA S.A." => "235",
      "CONSORCIO CORREDORES DE BOLSA S.A." => "236",
      #Institución Autorizada APVI - APVC: Bancos
      "Banco Santander Santiago" => "321"
    }
  end

  protected

  def default_payment_message
    self.payment_message ||= I18n.t(
      'views.remunerations.salary_payments.certificate_text_html',
      community_administrator: community.to_s
    )
  end

  def parse_payment_message
    return if payment_message.blank?

    self.payment_message =
      self.payment_message.gsub(/(%{community_administrator})/, community.to_s)
  end
end
