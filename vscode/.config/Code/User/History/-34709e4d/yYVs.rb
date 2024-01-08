# == Schema Information
#
# Table name: excel_uploads
#
#  id                :integer          not null, primary key
#  admin             :boolean          default(FALSE)
#  cancelled_at      :datetime
#  error             :text
#  excel             :string
#  excel_updated_at  :datetime
#  imported          :boolean          default(FALSE)
#  name              :string
#  result            :string
#  result_updated_at :datetime
#  unsafe_import     :boolean          default(FALSE)
#  uploaded_by       :integer
#  with_creation     :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  cancel_user_id    :integer
#  community_id      :integer
#
require 'roo'
require 'yaml'
# require "internals/excel_load"

class ExcelUpload < ApplicationRecord
  include Formatter
  include AttachmentTimerUpdater

  has_many   :bill_details, as: :importer, inverse_of: :importer
  has_many   :bills, as: :importer, inverse_of: :importer
  belongs_to :cancel_user, foreign_key: :cancel_user_id, optional: true, class_name: 'User'
  has_many   :common_expenses, as: :importer, inverse_of: :importer
  belongs_to :community, optional: true
  has_many   :guest_registries
  has_many   :incomes, as: :importer, inverse_of: :importer
  has_many   :marks
  has_many   :payments, as: :importer, inverse_of: :importer
  has_many   :properties, as: :importer, inverse_of: :importer
  has_many   :property_fines
  has_many   :property_users, as: :importer, inverse_of: :importer
  has_many   :provisions
  has_many   :service_billings, as: :importer, inverse_of: :importer
  has_many   :subproperties, as: :importer, inverse_of: :importer
  belongs_to :user, foreign_key: :uploaded_by, optional: true
  has_many   :users, as: :importer, inverse_of: :importer

  mount_uploader :excel, ExcelUploader
  mount_uploader :result, ExcelUploader

  validate :check_excel_size, on: :save, unless: proc { |eu|
    eu.name == 'Cartola' || eu.name&.capitalize == I18n.t('views.bills.business_transaction.one')
  }

  IMPORTERS = {
    'Copropietarios'                                  => 'Copropietarios',
    'Egresos'                                         => 'Egresos',
    'Cargos'                                          => 'Cargos',
    'Lecturas'                                        => 'Lecturas',
    'Provisiones'                                     => 'Provisiones',
    'Recaudación'                                     => 'Recaudación',
    'Saldos'                                          => 'Saldos',
    'PagosAgrupados'                                  => 'PagosAgrupados',
    'SubPropiedades'                                  => 'SubPropiedades',
    'TransferenciasPropiedades'                       => 'TransferenciasPropiedades',
    'TransferenciasSubpropiedades'                    => 'TransferenciasSubpropiedades',
    'Cartola'                                         => 'Cartola',
    'Boletas'                                         => 'Boletas',
    'Lecturas-Iniciales'                              => 'Lecturas-Iniciales',
    'Deudas'                                          => 'Deudas',
    I18n.t('activerecord.models.property_user.other') => I18n.t('activerecord.models.property_user.other'),
    'guest_registries_admin'                          => I18n.t('views.admin.communities.importers.guest_registries_admin'),
    'guest_list'                                      => I18n.t('views.admin.communities.importers.guest_list'),
    I18n.t('activerecord.models.aliquot.other')       => I18n.t('activerecord.models.aliquot.other')
  }.freeze

  UNDO_IMPORTERS = [
    'Copropietarios',
    I18n.t('activerecord.models.property_user.other'),
    'Saldos',
    'Lecturas',
    'Egresos',
    'Recaudación',
    'Recaudacion',
    'Cargos',
    'Cartola',
    I18n.t('views.bills.business_transaction.one'),
    'Deudas'
  ].freeze
  GLOBAL_IMPORTERS = %w[Invoices CopropietariosGlobales InvoicePayments KushkiMxDispersions].freeze

  IMPORTER_CLASSES = {
    'Cargos'                                          => PropertyFine,
    'Cargos_NPCC'                                     => PropertyFine,
    'Copropietarios'                                  => PropertyUser,
    I18n.t('activerecord.models.property_user.other') => PropertyUser,
    'Egresos'                                         => ServiceBilling,
    'guest_list'                                      => GuestRegistry,
    'guest_registries_admin'                          => GuestRegistry,
    'Ingresos'                                        => Income,
    'Lecturas'                                        => Mark,
    'Lecturas-Iniciales'                              => Mark,
    'PagosAgrupados'                                  => BundlePayment,
    'Provisiones'                                     => Provision,
    'Recaudacion'                                     => Payment,
    'TransferenciasPropiedades'                       => Transfer,
    'TransferenciasSubpropiedades'                    => Transfer,
    I18n.t('activerecord.models.aliquot.other')       => Aliquot
  }.freeze

  def check_excel_size
    return if excel.size < 2.megabytes

    errors.add(:excel, I18n.t('activerecord.errors.models.excel_upload.attributes.excel.invalid_file_size'))
  end

  # check
  def importer(params, records=[])
    ExcelImporter.new(params, records, self).call
  end

  def importers_modules
    {
      'InvoicePayments' => 'InvoicePayments',
      'Copropietarios' => 'PropertyUsersAndProperties',
      'Saldos' => 'CommonExpenses',
      'SubPropiedades' => 'Subproperties',
      'KushkiMxDispersions' => 'KushkiMxDispersions'
    }
  end

  # RECORDAR QUE LA TRANSCRIPCIÓN DEBE SER ÚNICA
  def translate_params(value)
    value = value.to_s.downcase.strip
    if name == 'PagosAgrupados'
      result = translate_bundle_payment_params[value]
    else
      result = known_params[value]
      result ||= translate_dynamic_params(value)
    end
    result || value
  end

  def translate_dynamic_params(value)
    dynamic_aliquot_param = translate_dynamic_aliquot_params(value)
    return dynamic_aliquot_param unless dynamic_aliquot_param.blank?

    if value.start_with?('propiedad relacionada ') || value.start_with?('propiedad ')
      n = value.split(' ').last
      return "subproperties[#{n}][name]"
    end
    return value unless value.start_with?('% de ')

    # % de Fondos a Fondo pintura
    # % de Alícuota a Torre 2
    # % de Medidores a Medidor 1
    split_values = value.split(' ')
    if split_values.size >= 5
      proratable_type = split_values[2]
      # proratable_type == Fund/Aliquot/Meter.model_name.human.downcase
      proratable_name = split_values.drop(4).join(' ')
      return "service_billing_meters[#{proratable_type}][#{proratable_name.delete('%')}][value]"
    end
    value
  end

  def translate_dynamic_aliquot_params(value)
    { name: 'nombre', size: 'tamaño' }.each do |k, v|
      next unless value.downcase.start_with?("#{v} alícuota ", "#{v} alicuota ")

      n = value.split(' ').last
      return "aliquots[#{n}][#{k}]"
    end
    nil
  end

  def get_property_user_identification
    identification = Countries.get_identity_type(self.community.country_code)&.first.to_s.downcase
    {identification => "user[#{identification}]"}
  end

  def known_params
    [translate_business_transaction_params,
     translate_debt_params, translate_general_params, translate_income_params,
     translate_mark_params, translate_payment_params,
     translate_property_fine_params, translate_property_transfer_params,
     translate_provision_params,
     translate_service_billing_params, translate_subproperty_transfer_params,
     translate_transfer_params, translate_guest_list_params].reduce(:merge)
  end

  def translate_bundle_payment_params
    {
      'comentarios'                         => 'bundle_payment[description]',
      'comentarios del pago (agrupado)'     => 'bundle_payment[description]',
      'fecha'                               => 'bundle_payment[paid_at]',
      'fecha de pago (agrupado)'            => 'bundle_payment[paid_at]',
      'id'                                  => 'account_summary_sheet[id]',
      'Id Boleta agrupada'                  => 'account_summary_sheet[id]',
      'Id estado de cuenta agrupado'        => 'account_summary_sheet[id]',
      'medio de pago'                       => 'bundle_payment[payment_type]',
      'medio de pago (agrupado)'            => 'bundle_payment[payment_type]',
      'monto'                               => 'bundle_payment[price]',
      'monto a pagar (agrupado)'            => 'bundle_payment[price]',
      'número documento'                    => 'bundle_payment[payment_number]',
      'número documento de pago (agrupado)' => 'bundle_payment[payment_number]'
    }
  end

  # GENERAL
  def translate_general_params
    {
      'año'                 => 'year',
      'mes'                 => 'month',
      'propiedad'           => 'property[address]',
      'unidad'              => 'property[address]',
      'comunidad'           => 'community_id',
      'nombre de propiedad' => 'property[name]'
    }
  end

  # CARGOS
  def translate_property_fine_params
    {
      'año cargo'                         => 'property_fine[year_fine]',
      'cantidad de cargos'                => 'property_fine[amount]',
      'cargo cobrado en boleta'           => 'property_fine[in_bill]',
      'cargo cobrado en estado de cuenta' => 'property_fine[in_bill]',
      'cargo contra el fondo de reserva'  => 'property_fine[reserve_fund]',
      'cargo omitido en boleta'           => 'property_fine[omitted_in_bill]',
      'cargo omitido en estado de cuenta' => 'property_fine[omitted_in_bill]',
      'día cargo'                         => 'property_fine[day_fine]',
      'fondo asociado'                    => 'property_fine[fund_name]',
      'mes cargo'                         => 'property_fine[month_fine]',
      'nombre del cargo'                  => 'property_fine[title]',
      'precio total del cargo'            => 'property_fine[price]',
      'precio unitario del cargo'         => 'property_fine[unit_price]',
      'descripcion del cargo'             => 'property_fine[description]',
      'descripción del cargo'             => 'property_fine[description]'
    }
  end

  # EGRESOS
  def translate_service_billing_params
    {
      'descripción egreso'                  => 'service_billing[name]',
      'descripción egresos'                 => 'service_billing[name]',
      'estado de pago'                      => 'service_billing[paid]',
      'fecha de pago del egreso'            => 'service_billing[paid_at]',
      'fecha del egreso'                    => 'service_billing[paid_at]',
      'folio egreso'                        => 'service_billing[folio]',
      'fondo de reserva'                    => 'service_billing[reserve_fund]',
      'medidor'                             => 'meter[name]',
      'medio de pago del egreso'            => 'service_billing[payment_type]',
      'monto del egreso'                    => 'service_billing[price]',
      'nombre categoría'                    => 'category[name]',
      'nombre categoria'                    => 'category[name]',
      'nombre proveedor'                    => 'supplier[name]',
      'nombre subcategoría'                 => 'category[sub_name]',
      'nombre subcategoria'                 => 'category[sub_name]',
      'notas adicionales para el egreso'    => 'service_billing[notes]',
      'notas acionales para el egreso'      => 'service_billing[notes]',
      'número de comprobante'               => 'service_billing[document_number]',
      'número documento de pago del egreso' => 'service_billing[payment_number]',
      'rut proveedor'                       => 'supplier[rut]',
      'rfc proveedor'                       => 'supplier[rut]',
      'tipo de comprobante'                 => 'service_billing[document_type]',
      'torre asignada'                      => 'aliquot_name',
      'alícuota asignada'                   => 'aliquot_name',
      'alicuota asignada'                   => 'aliquot_name'
    }
  end

  # LECTURAS
  def translate_mark_params
    {
      'lectura inicial' => 'mark[initial_value]',
      'lectura'         => 'mark[value]'
    }
  end

  # PROVISIONES
  def translate_provision_params
    {
      'año inicial'                => 'year',
      'mes inicial'                => 'month',
      'meses para reunir el fondo' => 'provision[months]',
      'monto a juntar'             => 'provision[goal]',
      'nombre de provisión'        => 'provision[name]',
      'tipo de provisión'          => 'provision[provision_type]'
    }
  end

  # RECAUDACIÓN
  def translate_payment_params
    {
      'año a pagar'              => 'year',
      'comentarios del pago'     => 'payment[description]',
      'facturar al crear'        => 'payment[generate_invoice_on_create]',
      'fecha de pago'            => 'payment[paid_at]',
      'folio'                    => 'payment[folio]',
      'medio de pago'            => 'payment[payment_type]',
      'mes a pagar'              => 'month',
      'monto a pagar'            => 'payment[price]',
      'número documento de pago' => 'payment[payment_number]'
    }
  end

  # TRANSFERENCIAS
  def translate_transfer_params
    {
      'apellido materno copropietario' => 'target_user[mother_last_name]',
      'apellido materno residente'     => 'target_user[mother_last_name]',
      'apellido paterno copropietario' => 'target_user[last_name]',
      'apellido paterno residente'     => 'target_user[last_name]',
      'email copropietario'            => 'target_user[email]',
      'email residente'                => 'target_user[email]',
      'fecha transferencia'            => 'transfer[transfer_date]',
      'nombre copropietario'           => 'target_user[first_name]',
      'nombre residente'               => 'target_user[first_name]',
      'porcentaje de transferencia'    => 'transfer[transfer_percentage]',
      'teléfono copropietario'         => 'target_user[phone]',
      'teléfono residente'             => 'target_user[phone]',
      'tipo transferencia'             => 'transfer[transfer_type]'
    }
  end

  # TRANSFERENCIAS DE PROPIEDADES RELACIONADAS
  def translate_subproperty_transfer_params
    {
      'propiedad de destino'    => 'target_property[name]',
      'unidad de destino'       => 'target_property[name]',
      'propiedad de origen'     => 'principal_property[name]',
      'unidad de origen'        => 'principal_property[name]',
      'propiedad relacionada 1' => 'subproperties[0][name]',
      'unidad relacionada 1'    => 'subproperties[0][name]',
      'propiedad relacionada 2' => 'subproperties[1][name]',
      'unidad relacionada 2'    => 'subproperties[1][name]',
      'propiedad relacionada 3' => 'subproperties[2][name]',
      'unidad relacionada 3'    => 'subproperties[2][name]',
      'propiedad relacionada 4' => 'subproperties[3][name]',
      'unidad relacionada 4'    => 'subproperties[3][name]'
    }
  end

  # TRANSFERENCIAS DE PROPIEDADES
  def translate_property_transfer_params
    {
      'propiedad 1 (principal)' => 'principal_property[name]',
      'unidad 1 (principal)'    => 'principal_property[name]',
      'propiedad 2'             => 'subproperties[0][name]',
      'unidad 2'                => 'subproperties[0][name]',
      'propiedad 3'             => 'subproperties[1][name]',
      'unidad 3'                => 'subproperties[1][name]',
      'propiedad 4'             => 'subproperties[2][name]',
      'unidad 4'                => 'subproperties[2][name]'
    }
  end

  # CARTOLA
  def translate_business_transaction_params
    {
      'descripcion'      => 'business_transaction[description]',
      'descripción'      => 'business_transaction[description]',
      'eliminar'         => 'destroy',
      'fecha movimiento' => 'business_transaction[transaction_date]',
      'id externo'       => 'business_transaction[external_id]',
      'transaccion'      => 'business_transaction[transaction_value]',
      'transacción'      => 'business_transaction[transaction_value]'
    }
  end

  # INGRESOS
  def translate_income_params
    {
      I18n.t('excels.import_incomes.headers.discount_after_common_expense').downcase              => 'income[after_funds]',
      I18n.t('excels.import_incomes.headers.date').downcase                                       => 'income[paid_at]',
      I18n.t('excels.import_incomes.headers.income_fund').downcase                                => 'income[fund_name]',
      I18n.t('excels.import_incomes.headers.payment_method').downcase                             => 'income[payment_type]',
      I18n.t('excels.import_incomes.headers.amount').downcase                                     => 'income[price]',
      I18n.t('excels.import_incomes.headers.name').downcase                                       => 'income[name]',
      I18n.t('excels.import_incomes.headers.notes').downcase                                      => 'income[note]',
      I18n.t('excels.import_incomes.headers.document_number').downcase                            => 'income[document_number]'
    }
  end

  # DEUDAS
  def translate_debt_params
    {
      'descripcion deuda'    => 'debt[description]',
      'descripción deuda'    => 'debt[description]',
      'monto deuda'          => 'debt[price]',
      'fecha vencimiento'    => 'debt[priority_date]',
      'deuda común'          => 'debt[common]',
      'deuda comun'          => 'debt[common]',
      'fecha inicio interés' => 'debt[last_interest_bill_date]',
      'fecha inicio interes' => 'debt[last_interest_bill_date]'
    }
  end

  # INVITADOS
  def translate_guest_list_params
    {
      'fecha de invitación'      => 'guest_registry[registered_at]',
      'nombre de invitado'       => 'guest_registry[name]',
      'comentario de invitación' => 'guest_registry[comment]'
    }.merge(translate_guest_list_identification_params)
  end

  def translate_guest_list_identification_params
    { I18n.t(:rut, scope: %i[excels guest_list upload_headers]).downcase => 'guest_registry[rut]' }
  end

  def send_email(info)
    return unless community.present?

    errors = []
    warnings = []
    info.each do |row_num, value|
      errors << I18n.t('mailers.notify_super_admin_importation.general.add_error', error: value[:errors].join(', '), row_num: row_num) if value[:errors].present?
      warnings << I18n.t('mailers.notify_super_admin_importation.general.add_error', error: value[:warnings].join(', '), row_num: row_num) if value[:warnings].present?
    end

    if imported
      content = I18n.t('mailers.notify_super_admin_importation.general.success', excel_file_name: excel.filename)
      subject = I18n.t('mailers.notify_super_admin_importation.subject.success', community_name: community.name)
    else
      content = errors
      subject = I18n.t('mailers.notify_super_admin_importation.subject.failure', community_name: community.name)
    end
    return unless user&.email.present?

    NotifySuperAdminImportationJob.perform_later(
      file_id: id, content: content, subject: subject, warnings: warnings,
      _message: I18n.t('mailers.notify_super_admin_importation.general.notify')
    )
  end

  def self.IMPORTERS
    IMPORTERS.map { |d| [d[1], d[0]] }
  end

  def self.GLOBAL_IMPORTERS
    GLOBAL_IMPORTERS.map { |d| [d, d] }
  end

  def self.UNDO_IMPORTERS
    UNDO_IMPORTERS
  end

  def import_data(next_excel_uploads_ids = [])
    modules = importers_modules
    if modules.keys.include?(name)
      Importers::Base.new(self, modules[name]).call
    else
      records = []
      info = Hash.new({})

      begin
        result =
          if unsafe_import
            process_import_data(records, info)
          else
            transaction_process(records, info)
          end

        # hacer actualización de errores
        update_errors(info)
        create_result_excel(result[:rows], info) if name == 'CopropietariosGlobales' && result[:rows].present?
      rescue StandardError => e
        handle_error(e, info)
      ensure
        save
        send_email(info)
      end

      return unless imported

      post_import_processing
    end

    return unless next_excel_uploads_ids.present?

    if imported
      excel_upload_id = next_excel_uploads_ids.shift
      DataImportJob.perform_later(excel_upload_id: excel_upload_id, next_excel_uploads_ids: next_excel_uploads_ids, _message: "Importando información de la comunidad #{community.id} - #{community}")
    else
      ExcelUpload.where(id: next_excel_uploads_ids).update_all(error: I18n.t('messages.errors.excel_uploads.previous_import_failed'))
    end
  end

  def update_errors(info)
    unless info.values.any? { |value| value[:errors].present? }
      self.imported = true
      return
    end
    self.error = info.reject { |_k, value| value[:errors].blank? }.map do |row_num, value|
      "Fila #{row_num}: #{value[:errors].join(', ')}"
    end.join(', ')
    self.imported = false
  end

  def transaction_process(records, info)
    result = {}
    ActiveRecord::Base.transaction do
      result = process_import_data(records, info)

      raise ActiveRecord::Rollback if info.values.any? { |value| value[:errors].present? }
    end
    result
  end

  def handle_error(error, info)
    Rollbar.log('error', error)
    Rollbar.error(error, community_id: community_id)
    self.error = 'Ha ocurrido un error importando el Excel'
    self.error += info.values.flat_map { |value| value[:errors] }.join(' ')
    # self.error += error.backtrace.join("\n")
    # self.error += error.to_s
    self.imported = false
  end

  def post_import_processing
    case name
    when 'Cartola', I18n.t('views.bills.business_transaction.one')
      UpdateAllBusinessTransactionsJob.perform_later(_community_id: community_id, community_id: community_id, _message: "Actualización de #{I18n.t('views.bills.business_transaction.other').downcase}")
    when 'Recaudación', 'Recaudacion'
      Payment.where(excel_upload_id: self.id).includes(:property, :period_expense).each do |payment|
        notify = community&.auto_notify_payments? && payment&.property&.users&.with_valid_email.present?
        payment.generate_pdf(notify: notify)
      end
    when 'Egresos'
      community.get_open_period_expense.set_request_calculate if self.errors.empty?
    when 'Boletas'
      period_expense = community.get_open_period_expense
      period_expense.update(
        paid: true, initial_setup: false, bank_reconciliation_closed: true,
        common_expense_generated: false
      )
      period_expense.pre_close(
        false, false, true,
        "Actualización forzada de #{I18n.t('views.common_expenses.conjuntion.the.other')} "\
        "#{I18n.t('views.common_expenses.other').downcase}", community_id
      )
      period_expense.get_next.first.update(enable: true)
    end
  end

  # @returns { rows: [], info: { row_number: { errors: [], warnings: [] }}, row_counter: integer }
  def process_import_data(records, info)
    total_rows = get_excel_length
    save = true
    process_n_rows(total_rows, records, info, save)
  end

  # Para procesar sólo las primeras N filas del archivo.
  # @returns { rows: [], info: { row_number: { errors: [], warnings: [] }}, row_counter: integer }
  def headers
    spreadsheet = open_spreadsheet
    return { info: { 0 => { errors: ['No se pudo abrir el Excel.'] }}, row_counter: 0 } unless spreadsheet

    spreadsheet.row(1)
  end

  def process_n_rows(n, records = [], info = Hash.new({}), save = false)
    period_expense = nil
    spreadsheet = self.open_spreadsheet
    return { info: { 0 => { errors: ['No se pudo abrir el Excel.'] }}, row_counter: 0 } unless spreadsheet # se pudo abrir el excel

    rows = []
    row_counter = 1
    (2..n.next).each do |number|
      row_counter += 1
      params = self.parse_params(spreadsheet.row(number), spreadsheet.row(1))
      rows << params

      # Sólo hacemos esto si queremos guardar la información
      next unless save

      if self.name == 'Saldos' && self.user.admin? && !period_expense.present? && params[:year].present? and params[:month].present?
        period_expense = self.community.get_period_expense(params[:month].to_i, params[:year].to_i)
        unless period_expense.initial_setup
          period_expense.initial_setup = true
          period_expense.paid = true
          period_expense.save
          last = period_expense.get_last.first
          last.initial_setup = true
          last.paid = true
          last.save
          last.pre_close false, true
        end
        # Poner initial_setup a false para todos los demás period_expenses de la comunidad
        self.community.period_expenses.where('period_expenses.period > ?', period_expense.period).update_all(initial_setup: false, common_expense_generated: false)
      end

      # Ordenador de importadores a usar
      # obj_errors: { errors: [], warnings: [] }
      obj_info = self.importer(params, records)
      if obj_info.present?
        if info[row_counter].has_key?(:errors)
          info[row_counter][:errors] += obj_info[:errors]
          if info[row_counter].has_key?(:warnings)
            info[row_counter][:warnings] += obj_info[:warnings]
          else
            info[row_counter][:warnings] = obj_info[:warnings]
          end
        else
          info[row_counter] = obj_info
        end
      end
    end

    logger.error "Importación de excel ##{id} tiene #{info.length} errores"

    if save
      imported = true
      self.save
      if name == 'Saldos' && user.admin? && period_expense.present?
        period_expense.pre_close(false, false, true, "Actualización forzada de #{I18n.t('views.common_expenses.conjuntion.the.other')} #{I18n.t('views.common_expenses.other').downcase}", community_id)
        period_expense.get_next.first.update(enable: true)
      elsif name == 'Boletas'
        period_expense = records.first&.period_expense
        records.each do |bill|
          bill.price = bill.bill_details.sum(:price)
          bill.expiration_date = period_expense&.expiration_date&.to_time
          bill.save
        end
      elsif name == 'Cartola' || name == I18n.t('views.bills.business_transaction.one')
        BusinessTransaction.import(records)
        BusinessTransaction.reorder_excel_transactions(id)
      end
    end
    # info: { row_num => { errors: [], warnings: [] }}
    { rows: rows, info: info, row_counter: row_counter }
  end

  # Retorna el número de elementos contenidos en el excel.
  def get_excel_length
    spreadsheet = self.open_spreadsheet
    if spreadsheet
      return (2..spreadsheet.last_row).size
    else
      return { info: { 0 => { errors: ['No se pudo abrir el Excel.'] }}, row_counter: 0 }
    end
  end

  def open_spreadsheet
    excel_ignoring_hidden = nil
    excel_respond = nil
    case excel.filename.to_s.split('.')[-1] # [/[^?]+/]
    when 'xls'
      excel_respond = Roo::Excel.new(URI.parse(excel.expiring_url(60)).open.set_encoding('BINARY'))
      excel_ignoring_hidden = Roo::Excel.new(URI.parse(excel.expiring_url(60)).open.set_encoding('BINARY'), only_visible_sheets: true)
    when 'xlsx'
      excel_respond = Roo::Excelx.new(URI.parse(excel.expiring_url(60)).open.set_encoding('BINARY'))
      excel_ignoring_hidden = Roo::Excelx.new(URI.parse(excel.expiring_url(60)).open.set_encoding('BINARY'), only_visible_sheets: true)
    else false
    end#esta solucion es parche, porque la gema no entrega correctamente los only visible, en caso de llamarse igual las hojas visibles y las invisibles existira el mismo error.
    excel_respond.default_sheet = excel_ignoring_hidden.sheets[0]
    excel_respond
  end

  def parse_params(line, params)
    parsed = ''
    params.each_with_index do |val, key|
      parsed += "&#{self.translate_params(val)}=#{line[key].to_s.gsub('%', '%25').gsub('+', '%2B').gsub(';', '%3B').gsub('&', '%26')}"
    end
    parsed = Rack::Utils.parse_nested_query parsed
    parsed = ActionController::Parameters.new(parsed)
    parsed
  end

  def undo_upload(current_user = nil)
    success = true
    i_have_generated_common_expenses = PeriodExpense.where(initial_setup: false, common_expense_generated: true, community_id: self.community_id).exists?
    case name
    when 'Copropietarios', I18n.t('activerecord.models.property_user.other')
      # Las propiedades no se eliminan por ser una acción muy riesgosa!
      # Property.undo_excel_import self
      nullify_import_by_name(current_user)
      self.error = if self.error ==  I18n.t('messages.errors.excel_uploads.undo_properties')
                     'Excel anulado (FULL)'
                   else
                     "Excel anulado (#{I18n.t('activerecord.models.property_user.other').downcase})"
                   end
    when 'Saldos', 'Cartola', I18n.t('views.bills.business_transaction.one')
      success = i_have_generated_common_expenses ? false : nullify_import_by_name(current_user)
    when 'Lecturas', 'Egresos', 'Recaudación', 'Recaudacion', 'Cargos', 'Deudas'
      success = nullify_import_by_name(current_user)
    end
    post_undo_processing(success, current_user)
  end

  def post_undo_processing(success, current_user = nil)
    if success
      unless name.in? %w(Recaudación Recaudacion Copropietarios) || name == I18n.t('activerecord.models.property_user.other')
        self.error = 'Excel anulado'
      end

      if name.in? %w(Recaudación Recaudacion)
        self.error = ''
        self.cancelled_at = Time.current
        self.cancel_user_id = current_user.id
      end

      community.get_open_period_expense.set_request_calculate if name == 'Egresos'
    end
    save

    success
  end

  def nullify_import_by_name(current_user)
    nullifier_classes_by_name[name].all? do |importer_class|
      meth = importer_class.method(:undo_excel_import)
      meth_args = meth.parameters.count > 1 ? [self, current_user] : [self]
      importer_class.undo_excel_import(*meth_args)
    end
  end

  def nullifier_classes_by_name
    {
      'Copropietarios'                                  => [User],
      I18n.t('activerecord.models.property_user.other') => [User],
      'Saldos'                                          => [CommonExpense],
      'Lecturas'                                        => [Mark],
      'Egresos'                                         => [ServiceBilling],
      'Recaudación'                                     => [Payment],
      'Recaudacion'                                     => [Payment],
      'Cargos'                                          => [PropertyFine],
      'Deudas'                                          => [Debt],
      'Cartola'                                         => [Debt],
      I18n.t('views.bills.business_transaction.one')    => [BusinessTransaction]
    }
  end

  def undo_upload_properties
    Property.undo_excel_import self

    self.error = if self.error == "Excel anulado (#{I18n.t('activerecord.models.property_user.other').downcase})"
                   'Excel anulado (FULL)'
                 else
                   I18n.t('messages.errors.excel_uploads.undo_properties')
                 end
    self.save
  end

  def create_result_excel(rows, info)
    # Crear folders
    dirname = File.dirname('user_temp/excel_uploads/')
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    path = "user_temp/excel_uploads/#{id}#{Time.now.to_i.to_s[6..10]}.xlsx"
    stream = ExcelUpload.create_result_sheet(rows, info).to_stream
    file = File.new(path, 'w')
    file << stream.read
    self.result = file
    file.close
    File.delete(path)
  end

  def self.create_result_sheet(rows, info)
    result_sheet = {}
    result_sheet[:name] = 'Excel de resultados'
    result_sheet[:title] = ['', 'Resultados de importación']
    result_sheet[:body] = []
    result_header = ['']
    keys = rows.flat_map do |row|
      row.map { |key, value| value.is_a?(Hash) ? { key => value.keys } : key }
    end.uniq
    result_header += keys.flat_map do |key|
      key.is_a?(Hash) ? key.flat_map { |k, v| v.map { |v2| "#{k}[#{v2}]" } } : key.to_s
    end
    result_header << 'Errores' if info.values.any? { |value| value[:errors].present? }
    result_sheet[:header] = result_header
    rows.each.with_index(2) do |row, index|
      result_row = ['']
      result_row += keys.flat_map do |key|
        key.is_a?(Hash) ? key.flat_map { |k, v| v.map { |v2| row[k][v2] } } : row[key] || ''
      end
      result_row << info[index][:errors].join(', ') if info[index][:errors].present?
      result_sheet[:body].append(content: result_row)
    end
    format_to_excel([result_sheet])
  end

  def payments_can_be_unimported?(period_id)
    return false if payments.blank? || cancelled?

    if community.uses_period_control?
      all_payments_in_same_period?(period_id)
    else
      all_payments_without_bill?
    end
  end

  def all_payments_in_same_period?(period_id)
    payments.all? { |p| p.period_expense_id == period_id }
  end

  def all_payments_without_bill?
    payments.all? { |p| !p.irs_billed? }
  end

  def cancelled?
    !cancelled_at.nil?
  end
end
