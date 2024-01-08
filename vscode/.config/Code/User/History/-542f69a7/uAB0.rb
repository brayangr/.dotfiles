require 'period_closing/debts_update_calculation'

module PeriodControl
  include ClosingLogHelper
  PropertyStruct = Struct.new('PropertyStruct', :name, :uri_to_add)

  # Método separado para marcar flags antes del cierre del
  def pre_close(delay = true, recalculate = false, notify = true, closed_by_user = false, message = "Preparando cierre del #{I18n.t('views.common_expenses.one').downcase}", community_id = nil, current_user = nil, new_bt_date = nil)
    log_closing_step(period_expense: self, create_log: true, step_name: Constants::ClosingLog::STEPS_COLLECTION[:preclose]) do |closing_log|
      return false if self.community.properties.any?{|property| property.proration < 0}
      provision_in_last_months = ProvisionPeriodExpense.joins(:period_expense).where(period_expenses: {community_id: self.community.id}).where('period_expenses.period > ?', self.period - 3.months).exists?
      if(!provision_in_last_months && (self.community.get_setting_value('enabled_provisions') != 0))
        self.community.get_setting('enabled_provisions').update(value: 0)
      end
      return false if self.common_expense_generated
      # Bloquear el antiguo gasto común
      self.community.last_closed_period_expense.update(blocked: true) if self.community.last_closed_period_expense.present?
      self.common_expense_generated = true
      self.closed_by_user = closed_by_user
      self.common_expense_generated_at = Time.now
      self.blocked = true
      self.save

      PeriodControl::ClosingJobEnqueuer.new(
        period_expense: self,
        current_user: current_user,
        delay: delay,
        recalculate: recalculate,
        notify: notify,
        new_bt_date: new_bt_date,
        message: message,
        closing_log: closing_log
      ).enqueue_jobs
    end
  end

  def close(delay = true, recalculate = false, notify = true, current_user = nil, new_bt_date = nil, closing_log_id = nil)
    if recalculate
      self.community.last_closed_period_expense.update(blocked: false) if self.community.last_closed_period_expense.present?
      self.common_expense_generated = false
      self.save
      # recalcular datos
      self.start_flag
      self.community.generate_period_expense(self.period.month, self.period.year)
    end

    PeriodControl::DataFixer.new(period_expense: self).destroy_wrong_data

    # Bloquear el antiguo gasto común
    self.community.last_closed_period_expense.update(blocked: true) if self.community.last_closed_period_expense.present?

    self.common_expense_generated = true
    self.common_expense_generated_at = Time.now

    # Crear o actualizar la info. de precios de medidores
    self.community.meters.each do |meter|
      meter_id = meter.id
      period_expense_id = self.id
      meterperiod = MeterPeriod.where('meter_id = ? AND period_expense_id = ?', meter_id, period_expense_id).first
      meterperiod = MeterPeriod.new({ meter_id: meter_id, period_expense_id: period_expense_id }) if meterperiod.nil?
      meterperiod.update({
                          unit_price: meter.unit_price,
                          is_fixed: self.community.get_setting_value('meter_calculation') == 1
                        })
    end

    self.save
    if delay
      NotifyCloseJob.perform_later(_community_id: community_id, period_expense_id: id, delay: true, notify: notify, _message: 'Generando el cierre del Gasto Común, paso 1', current_user: current_user, new_bt_date: new_bt_date, closing_log_id: closing_log_id)
    else
      self.notify_close(false, notify, current_user, new_bt_date)
    end

    # revisar aspectos adicionales
    self.review_activation
  end

  def notify_close(delay = true, notify = true, current_user = nil, new_bt_date = nil, closing_log_id = nil)
    PeriodClosing::DebtsUpdateCalculation.update_debts(community.id)
    payments = Payment.joins(:property)
                      .eager_load(:property)
                      .preload(property: [debts: [:interest, assign_payments: [:payment], interests: [:debt], period_expense: [:discounts] ]])
                      .where(properties: { community_id: community.id }, completed: false, nullified: false, undid: false)
                      .order(created_at: :desc)
    #DOUBLE CHECK DE QUE SE PUEDE CERRAR EL GC
    payments.each do |payment|
      payment.assign_common_expense(
        compensation: true,
        debt_ids: [],
        debts_amount: {},
        cached: true
      )
    end

    #marcar confirmados
    self.payments.where(confirmed: true).update_all issued: true
    self.bundle_payments.where(confirmed: true).update_all issued: true

    # cerrar coutas del gasto común
    self.provision_period_expenses.each do |p|
      p.set_issued
    end

    # Cerrar multas
    self.property_fines.update_all issued: true
    # self.property_fines.each do |p|
    #   p.set_issued
    # end


    # calcular intereses para este mes, desde las deudas del mes anterior,
    # excepto en el setup inicial
    unless self.initial_setup
      current_date = self.close_interest_date
      community.current_interest.create_interest self, current_date
    end

    # Crear transacciones para intereses
    new_interest_date = new_bt_date.present? ? new_bt_date - 5.seconds : nil
    Interest.create_transactions(community, self.id, new_interest_date)

    common_expenses.update_all(initial_setup: true) if initial_setup

    if delay
      NotifyClose2Job.perform_later(_community_id: community_id, period_expense_id: id, delay: true, notify: notify, _message: 'Generando el cierre del Gasto Común, paso 2', current_user: current_user, new_bt_date: new_bt_date, closing_log_id: closing_log_id)
    else
      notify_close_2(delay: false, notify: notify, user: current_user, new_bt_date: new_bt_date, closing_log_id: closing_log_id)
    end
  end

  def notify_close_2(delay: true, notify: true, user: nil, new_bt_date: nil, closing_log_id: nil)
    CommonExpense.verify_all(period_expense: self, user: user, new_bt_date: new_bt_date) unless initial_setup || community.integration&.import_bills?

    if delay
      NotifyClose3Job.perform_later(_community_id: community_id, period_expense_id: id, delay: true, notify: notify, new_bt_date: new_bt_date, _message: 'Generando el cierre del Gasto Común, paso 3', current_user: user, closing_log_id: closing_log_id)
    else
      notify_close_3(false, notify, user, new_bt_date, closing_log_id)
    end
  end

  def notify_close_3(delay = true, notify = true, current_user = nil, new_bt_date = nil, closing_log_id = nil)
    next_period_expense = get_next.first
    next_period_expense.payments.each do |p|
      p.assign_bill
      p.save
    end

    bills = self.bills

    parent_orphan_future_statements

    self.update global_amount: bills.inject(0) { |sum, pp | sum + pp.price }

    if self.community.get_setting_value('ass_enabled').positive?
      if delay
        BuildAccountSummarySheetsJob.perform_later(_community_id: self.community_id, period_expense_id: self.id, _message: 'Generando pdf de unidades agrupadas.', closing_log_id: closing_log_id)
        AssignBundlePaymentToAccountSummarySheetsJob.perform_later(_community_id: self.community_id, period_expense_id: self.id, _message: 'Asignando pagos agrupados del mes.', closing_log_id: closing_log_id)
      else
        AccountSummarySheet.build_sheets_from_period_expense(self)
        BundlePayment.assign_bundle_payment_to_account_summary_sheets(self)
      end
    end

    if self.initial_setup
      self.bill_generated = true
      self.bill_generated_at = Time.now
      self.save
      # TODO: FUNDS
      # Cerrar fund_period_expenses de los fondos
      # self.close_fund_period_expenses
    else
      current_user_is_admin = current_user&.admin?
      if delay
        # generar boletas individuales
        # self.bill_pdf_generation bills
        plan_bill_pdf_generation(bills, delay, current_user_is_admin, closing_log_id)
      else
        # Acá se ejecutan todos los pdf juntos. Se retorna true si se creó el item, por lo que
        # eso define si hay post procesamiento o no.
        db_item_created, item_name = prepare_bill_pdf_generation(bills, false, current_user_is_admin, closing_log_id)
        bills = bills.preload_for_pdf_generation
        bill_pdf_generation(bills, false, current_user_is_admin, true, db_item_created, item_name)
        # self.collect_all_pdf
      end
    end

    # Generar Avances y Egresos recurrentes
    unless undid
      byebug
      if delay
        GenerateRecurrentServiceBillingsJob.perform_later(_community_id: self.community_id, period_expense_id: self.id, _message: I18n.t('jobs.generate_recurrent_service_billings_job'), closing_log_id: closing_log_id)

        if remuneration_enabled?(community)
          GenerateRecurrentAdvancesJob.perform_later(_community_id: self.community_id, period_expense_id: self.id, _message: 'Generando avances recurrentes para el próximo período', closing_log_id: closing_log_id)
        end
      else
        byebug
        generate_recurrent_service_billings

        generate_recurrent_advances if remuneration_enabled?(community)
      end
    end

    # Los pagos no registrados porque se hicieron posteiormente
    next_period_expense.payments.where(undid: true).joins(:property).each do |p|
      payment_nullified = p.nullified
      payment_nullifier_id = p.nullifier_id
      p.update(nullifier_id: nil, nullified: false)
      p.assign_common_expense
      p.create_transaction
      p.nullify!(payment_nullifier_id) if payment_nullified
    end
    next_period_expense.payments.where(undid: true).update_all(undid: false) # los volvemos a marcar falsos para que sean utilizados en nuevos GC (no son utilizandos por las deudas cuando vienen con undid)

    # Si proviene del seteo inicial cuando se crea la comunidad
    if self.initial_setup
      bills.update_all(initial_setup: true)
      self.set_origin_debt_for_interest
    else
      community.get_open_period_expense.set_request_calculate false, delay
    end

    # TODO: FUNDS
    # Crear fund_period_expenses para los Fondos
    # community.funds.each do |fund|
    #   Fund.full_create fund.id, self.id
    # end
    self.close_fund_period_expenses

    Mark.update_negatives_marks(next_period_expense)
    self.update(blocked: false)

    # El gasto común fue generado. Crear el registro
    PeriodExpenseRegister.create(date: Time.now, description: "Se cerró el Gasto Común de #{I18n.l(self.period, format: :month_year)}", responsible: current_user, period_expense: self)
  end

  def parent_orphan_future_statements
    orphan_future_statements = FutureStatement.joins(property: :bills).where(bills: {period_expense_id: self.id}, bill_id: nil)
    orphan_future_statements.each do |fs|
      fs.create_bill
    end if orphan_future_statements.any?
  end

  def plan_bill_pdf_generation(bills, delay = false, current_user_is_admin = false, closing_log_id = nil)
    log_closing_step(period_expense: self, closing_log_id: closing_log_id, step_name: Constants::ClosingLog::STEPS_COLLECTION[:plan_bill_pdf_generation]) do |closing_log|
      workers = Integer(ENV['WORKLESS_MAX_WORKERS'] || 1) # workers disponibles
      max_queue = workers.present? ? [bills.length / workers, 40].min : 1 # que tan larga puede ser la cola, sin tener 2 jobs/worker
      slice = [Integer(ENV['BILL_SLICE'] || 20), max_queue].max # finalmente que largo tendra la fila, en caso de comunidades muy grande se usará max_queue

      # Acá se ejecutan todos los pdf juntos. Se retorna true si se creó el item, por lo que
      # eso define si hay post procesamiento o no.
      db_item_created, item_name = prepare_bill_pdf_generation(bills, false, current_user_is_admin, closing_log_id)

      bills.each_slice(slice).to_a.each_with_index do |bills_slice, index|
        bill_pdf_generation_job = BillPdfGenerationJob.new(
          _community_id: community_id,
          period_expense_id: self.id,
          bills_ids: bills_slice.map(&:id),
          delay: delay,
          first_call: index.zero?,
          post_processing: db_item_created,
          item_name: item_name,
          current_user_is_admin: current_user_is_admin,
          _message: I18n.t('jobs.bill_generation_properties') + " #{(index * slice) + 1}° a #{(index + 1) * slice}°.",
          index: index,
          closing_log_id: closing_log_id
        )
        bill_pdf_generation_job.queue_name = :low_ram_queue
        bill_pdf_generation_job.assign_queue_name
        bill_pdf_generation_job.enqueue
        # flags para apagar servidores con power
        # PlatformAPI.connect_oauth(ENV["YOUR_HEROKU_KEY"]).dyno.create(ENV["YOUR_HEROKU_APP_NAME"],{command: 'rake jobs:workoff'})
      end
    end
  end

  def prepare_bill_pdf_generation(bills, delay=false, current_user_is_admin=false, closing_log_id=nil)
    # Creamos el objeto en DynamoDb. Para eso debemos generar un id del objeto y calcular el
    # maximum (cantidad de pdfs que se generarán).

    item_name = "#{id}periodcontrol#{Time.now.to_i.to_s[4..10]}"
    maximum = bills.size

    # Debemos crear los argumentos de los jobs que se llaman después. Existen cambios en que,
    # por ejemplo, los objetos son reemplazados por el id.
    job_data = {
      'FinishAllTransfersJob': {
        _community_id: community_id,
        job_queue: ENV[FinishAllTransfersJob.queue_name.to_s],
        period_expense_id: id,
        attempt: 0,
        _message: I18n.t('jobs.finish_transfers'),
        closing_log_id: closing_log_id
      },
      'CollectAllPdfJob': {
        _community_id: community_id,
        job_queue: ENV[CollectAllPdfJob.queue_name.to_s],
        period_expense_id: id,
        notify: delay,
        _message: "#{I18n.t('jobs.instanced.collect_all_pdf')} #{community} - #{self}",
        current_user_is_admin: current_user_is_admin,
        closing_log_id: closing_log_id
      }
    }

    # Si tiene éxito creando el objeto, post_processing continuará siendo true. Si falla por
    # algún motivo, entonces será false y se encolarán los jobs con la estrategia antigua.
    success = Aws::DynamoDbClient.new.safe_create_item(item_name, maximum, job_data)
    [success, item_name]
  end

  def bill_pdf_generation(bills, delay = false, current_user_is_admin = false, first_call = true,
                            post_processing = false, item_name = '', index = 0, closing_log_id = nil)

    log_closing_step(period_expense: self, closing_log_id: closing_log_id, step_name: Constants::ClosingLog::STEPS_COLLECTION[:bill_pdf_generation] + " ##{index + 1}") do |closing_log|
      # Delayed::Job.scaler.up
      gen_info = BillsCommon::GenerationInfo.new(false, false, post_processing, item_name)
      community_info = BillsCommon::CommunityInfo.new(community)
      period_info = BillsCommon::PeriodInfo.new(community, self, false)
      bills.each do |bill|
        # Pasamos argumentos para que post_procesamiento sea true y el item_name calce con el creado.
        begin
          attempts ||= 1
          bill.generate_pdf(gen_info, community_info, period_info)
        rescue => e
          Rollbar.error(
            e, "Error in bill #{bill.id} pdf generation",
            bill_attributes: bill.to_json,
            community_id: community_id,
            period_expense_id: id,
            short_bill_file: bill.short_bill&.read,
            bill_file: bill.bill&.read,
            closing_start_at: common_expense_generated_at
          )
          if (attempts += 1) <= Constants::Bills::PDF_GENERATION_MAX_ATTEMPT
            retry
          end
        end
      end


      # La idea es evitar el encolamiento en el caso de que sí se cree el objeto en dynamo, o bien,
      # este no sea el primer llamado (para evitar que se encole muchas veces).
      return if !first_call || post_processing

      # Si falla la creación del objeto en DynamoDB, debemos asegurarnos de que
      # se ejecuten los dos Jobs FinishAllTransfersJob y CollectAllPdfJob y ellos se
      # autorregularán (si todavía no debe ejecutarse se auto-encola).
      # Está condicionado al booleano porque queremos que se encole una vez cada uno.
      FinishAllTransfersJob.perform_later(
        _community_id: community_id,
        period_expense_id: id,
        attempt: 0,
        _message: I18n.t('jobs.finish_transfers'),
        closing_log_id: closing_log_id
      )
      #Aqui colecciona todos los pdfs pero del slide no de todos por lo que puede que esté entrando varias veces al job
      CollectAllPdfJob.perform_later(
        _community_id: community_id,
        period_expense_id: id,
        notify: delay,
        _message: "#{I18n.t('jobs.instanced.collect_all_pdf')} #{community} - #{self}",
        current_user_is_admin: current_user_is_admin,
        closing_log_id: closing_log_id
      )
    end
  end

  # TODO refactor: move the 'unless self.initial_setup' condition to a top level to prevent unnecesary queries
  def send_bills_notifications(current_user, unsent_only = false)
    community = self.community
    ActiveRecord::Associations::Preloader.new(records: [community], associations: [:properties, { users: :property_users }]).call
    ActiveRecord::Associations::Preloader.new(records: [self], associations: %i[account_summary_sheets bills]).call
    Log.create(value: "#{I18n.t('logs.period_control.send_bills_notifications')}: #{community}", user_id: current_user.id, community_id: community.id, origin_class: 'PeriodExpense_Notify', origin_id: id)
    community.users.uniq.each do |user|
      account_summary_sheets = self.account_summary_sheets.select { |ass| ass.user_id == user.id }
      account_summary_sheets.each do |ass|
        NotifyAccountSummarySheetJob.perform_later(_community_id: community_id, account_summary_sheet_id: ass.id, _message: "#{I18n.t('jobs.instanced.notify_account_summary_sheet')} #{I18n.t('activerecord.models.property_user.one').downcase} #{ass.user}") unless self.initial_setup
      end

      if account_summary_sheets.empty?
        properties_ids = user.property_users.map(&:property_id)
        properties = community.properties.select { |p| properties_ids.include?(p.id) }.uniq
        properties.each do |property|
          bill = self.bills.detect { |b| b.property_id == property.id }
          next unless bill.present?
          next if unsent_only && bill.notified_at.present? && bill.outgoing_mails.any?

          NotifySingleUserJob.perform_later(
            _community_id: community_id,
            bill_id:       bill.id,
            user_id:       user.id,
            _message:      "#{I18n.t('jobs.instanced.notify_sigle_user')} #{property}"
          ) unless self.initial_setup
        end
      end
      Log.create(value: "#{I18n.t('logs.period_control.send_bill_notification')}: #{community}, #{I18n.t('activerecord.models.property_user.one').downcase}: #{user}", user_id: current_user.id, community_id: community.id, origin_class: 'User', origin_id: user.id )
    end
  end

  def pre_unclose(user: nil)
    force = user&.admin?
    return false if (blocked || initial_setup) && !force

    self.common_expense_generated = false
    self.common_expense_generated_at = nil
    self.global_amount = 0
    self.bill_generated = false
    self.bill_generated_at = nil
    self.undid = true
    start_flag
    save

    UnclosePeriodJob.perform_later(_community_id: community_id, period_expense_id: id, current_user: user, _message: "#{I18n.t('views.common_expenses.conjuntion.undoing')} #{I18n.t('views.common_expenses.conjuntion.the.one')} #{I18n.t('views.common_expenses.one').downcase} #{self}")
  end

  def unclose(current_user)
    PeriodControl::DataFixer.new(period_expense: self).destroy_wrong_data

    remove_pdf_bills!                  # Eliminar boletas individuals generadas

    remove_pdf_short_bills!            # Eliminar boletas individuales generadas
    remove_pdf_grouped_bills!          # Eliminar boletas agrupadas generadas

    remove_pdf_mixed_bills!            # Eliminar boletas combinadas generadas

    save
    next_period = get_next.first

    # TODO: MASS UPDATE
    interests_to_destroy, debt_ids = interests.where(to_undo: true).order('end_date desc').pluck(:id, :debt_id).transpose
    update_interests_debts if interests_to_destroy.present?
    interests_to_destroy ||= []
    debt_ids ||= []
    # deudas a destruir
    debt_ids += Debt.joins(:common_expense).where(common_expenses: { period_expense_id: id }).pluck(:id)
    # Destruir todas las asignaciones al GC

    assign_payments = AssignPayment.where(debt_id: debt_ids)
    payment_ids = assign_payments.map(&:payment_id)
    debts_to_update = assign_payments.map(&:debt_id)
    assign_payments.destroy_all

    # SOLO MARCAMOS LOS PAGOS HECHOS EN EL PERIODO EN CURSO
    next_period.payments.update_all(undid: true) # Esto es para no marcarlos al emitir el gc nuevamente
    new_payment_ids = next_period.payments.pluck(:id)
    new_payment_properties = next_period.payments.pluck(:property_id)
    assign_payments = AssignPayment.where(payment_id: new_payment_ids)
    debts_to_update += assign_payments.pluck(:debt_id)
    assign_payments.destroy_all
    payment_ids += new_payment_ids

    # Destruir los intereses generados por los nuevos pagos:
    next_period.interests.destroy_all

    # Destruir los pagos tipo ajuste por gasto comun negativo
    next_period.payments.where(payment_type: 'adjustment', compensation: true, origin_payment_id: nil).destroy_all

    # Destruir las compensaciones generadas.
    assign_payments = AssignPayment.where(payment_id: next_period.payments.source_compensation.pluck(:id))
    debts_to_update += assign_payments.pluck(:debt_id)
    assign_payments.destroy_all
    next_period.payments.source_compensation.destroy_all
    next_period.payments.source_discount.destroy_all

    # Hacer efectivas las transferencias de propiedades
    rollback_all_transfers

    BusinessTransaction.joins('JOIN interests ON interests.property_transaction_id = business_transactions.id').where('interests.period_expense_id = ?', id).delete_all
    BusinessTransaction.joins('JOIN common_expenses ON common_expenses.property_transaction_id = business_transactions.id').where('common_expenses.period_expense_id = ?', id).delete_all
    BusinessTransaction.joins("JOIN payments ON payments.id = business_transactions.origin_id and business_transactions.origin_type = 'Payment' ").where('payments.period_expense_id = ?', next_period.id ).delete_all
    UpdateAllBusinessTransactionsJob.perform_later(_community_id: community_id, community_id: community_id, _message: "Actualización de #{I18n.t('views.bills.business_transaction.other').downcase}")

    Debt.where(id: debt_ids).delete_all

    # A estas alturas ya se borraron todas las debts y business transactions asociados a los intereses
    interests.where(id: interests_to_destroy).delete_all

    CommonExpenseDetail.joins(:common_expense).where(common_expenses: { period_expense_id: id }).delete_all
    Interest.joins(origin_debt: :common_expense).where(common_expenses: { period_expense_id: id }).delete_all
    CommonExpense.where(period_expense_id: id).delete_all

    provision_period_expenses.update_all(issued: false)
    property_fines.update_all(issued: false)

    Payment.where(id: payment_ids).update_all({ issued: false, completed: false })
    BundlePayment.where(period_expense_id: get_next.first.id).update_all(undid: true)

    # CachedPdf.where(bill_id: bills.pluck(:id) ).delete_all
    FundMovement.joins(bill_detail: :bill).where(bills: { period_expense_id: id }).delete_all
    FutureStatement.joins(:bill).where(bills: { period_expense_id: id }).update_all(bill_id: nil)
    BillDetail.joins(:bill).where(bills: { period_expense_id: id }).delete_all
    Bill.where(period_expense_id: id).delete_all

    AccountSummarySheet.where(period_expense_id: id).destroy_all

    # Deshacer cierre de fondos
    destroy_all_fund_period_expenses

    # RECALCULAMOS EL NUEVO PERIOD EXPENSE ABIERTO
    open = community.get_open_period_expense
    open.set_request_calculate

    # Desbloquear pagos
    open.payments.update_all(issued: false)
    open.bundle_payments.update_all(issued: false)

    # Notificar por correo cuando el periodo se esté listo
    # TODO: no se si esto es necesario... según yo no
    open.payments.where(undid: false).each do |p|
      p.assign_common_expense
    end

    # actualizar los saldos de las deudas
    update_debts_calculation(debts_to_update.compact.uniq, new_payment_properties.compact.uniq)
    puts 'debts_to_update: ' + debts_to_update.to_s
    # Si terminó de deshacerlo, crear el registro de que se deshizo
    PeriodExpenseRegister.create(date: Time.now, description: "Se deshizo el Gasto Común de #{I18n.l(self.period, format: :month_year)}", responsible: current_user, period_expense: self)
  end

  def update_interests_debts
    sql = %(
      UPDATE debts
      SET last_interest_bill_date = interests.start_date
      FROM (
        SELECT DISTINCT ON(origin_debt_id) interests.start_date,
          interests.origin_debt_id
        FROM interests
        WHERE interests.period_expense_id = #{self.id}
        ORDER BY origin_debt_id, end_date desc
        )
        AS interests
      WHERE interests.origin_debt_id = debts.id
    )
    ActiveRecord::Base.connection.execute(sql)
  end

  def update_debts_calculation(debts_to_update, new_payment_properties)
    sql = %(
      UPDATE debts
      SET money_paid = COALESCE(assign_payments.ap_sum, 0),
      money_balance = debts.price - COALESCE(assign_payments.ap_sum, 0)
      FROM (
        SELECT debts.id AS debt_id,
          SUM(assign_payments.price) AS ap_sum
        FROM debts
        LEFT JOIN assign_payments
          ON assign_payments.debt_id = debts.id
        WHERE debts.id IN (#{([0] + debts_to_update).join(', ')})
        OR debts.property_id IN (#{([0] + new_payment_properties).join(', ')})
        GROUP BY debts.id
        )
        AS assign_payments
      WHERE assign_payments.debt_id = debts.id
    )
    ActiveRecord::Base.connection.execute(sql)
  end

  def retry_collect_all_pdf_job(notify:, current_user_is_admin:, job_attempts: 1, closing_log_id: nil)
    CollectAllPdfJob.set(wait: 1.minutes).perform_later(
      _community_id: community_id,
      period_expense_id: id,
      notify: notify,
      _message: "#{I18n.t('jobs.instanced.collect_all_pdf3')} #{community} - #{self}",
      current_user_is_admin: current_user_is_admin,
      attempts: job_attempts,
      closing_log_id: closing_log_id
    )
  end

  def collect_all_pdf(notify = false, current_user_is_admin = false, method_attempts = 1, closing_log_id = nil)
    #aqui se empieza a combinar
    #Aquí se hizo un intento de verificacion de boletas sin pdf y si existen, envia nuevamente el job
    if bills_without_pdf.exists? || short_bills_without_pdf.exists? || (self.community.get_setting_value('ass_enabled').positive? && self.account_summary_sheets.where(summary_sheet: nil).exists?) || self.bills.sort_by(&:updated_at).any? { |b| !b.bill? || !b.short_bill? }
      Log.create(value: 'Bills without pdf in collect_all_pdf', community_id: community_id, origin_class: 'PeriodExpense', origin_id: id)
      retry_collect_all_pdf_job notify: notify, current_user_is_admin: current_user_is_admin
    else
      pdf = CombinePDF.new
      pdf_short = CombinePDF.new

      # Crear folders
      dirname = File.dirname('user_temp/period_expenses/')
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

      bills = self.bills.joins(:property).where(properties: { print: true })
      bills = bills.merge(Property.order(:priority_order)) unless community.get_setting_value('property_order').zero?
      bills = bills.merge(Property.order_by_name)

      bills.each do |bill|
        begin
          pdf << CombinePDF.parse(FileGetter.safe_get_file(bill.bill.expiring_url(86_400)))
          pdf_short << CombinePDF.parse(FileGetter.safe_get_file(bill.short_bill.expiring_url(86_400)))
        rescue => e
          Rollbar.error(
            e, "Error in bills combination pdf with bill: #{bill.id}",
            bill_attributes: bill.to_json,
            community_id: community_id,
            period_expense_id: id,
            short_bill_file: bill.short_bill&.read,
            bill_file: bill.bill&.read,
            closing_start_at: common_expense_generated_at
          )
          bill.generate_pdf if bill.bill.blank? || bill.short_bill.blank?
          retry_collect_all_pdf_job(notify: notify, current_user_is_admin: current_user_is_admin, job_attempts: method_attempts+=1, closing_log_id: closing_log_id)
          return
        end
      end

      # combinar
      name = "user_temp/period_expenses/combined_#{id}#{Time.now.to_i.to_s[6..10]}.pdf"
      pdf.save(name)
      name_short = "user_temp/period_expenses/short_combined_#{id}#{Time.now.to_i.to_s[6..10]}.pdf"
      pdf_short.save(name_short)

      # guardar
      file = File.new(name)
      file2 = File.new(name_short)
      self.pdf_bills = file
      self.pdf_short_bills = file2
      save
      file.close
      file2.close

      # limpiar
      File.delete(name)
      File.delete(name_short)

      # Generar pdf mixto
      self.generate_mixed_pdf_receipts
      community = self.community
      administrator = community.administrator

      if administrator.present? && !current_user_is_admin
        if administrator.email.present? && notify && !self.initial_setup # !request_test_or_local
          month_str = I18n.t('date.abbr_month_names')[month].capitalize
          NotifyCloseCommonExpenseJob.perform_later(
            community_id: community.id,
            period_expense_id: id,
            subject: I18n.t('mailers.notify_close_common_expense.subject', community_name: community.name, month: month_str, year: year),
            user_id: administrator.id,
            _message: I18n.t('mailers.notify_close_common_expense.message')
          )
        end
      end
    end
  end


  def collect_account_summary_sheet
    pdf = CombinePDF.new
    dirname = File.dirname('user_temp/period_expenses/')
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    account_summary_sheets.includes(bills: :property).order('properties.id asc').each do |b|
      url = b.summary_sheet.expiring_url
      pdf << CombinePDF.new(FileGetter.safe_get_file(url, 3)) if url.present?
    end

    name = "user_temp/period_expenses/summary_sheet_#{id}#{Time.now.to_i.to_s[6..10]}.pdf"
    pdf.save(name)

    file = File.new(name)
    update(pdf_grouped_bills: file)
    file.close
    File.delete(name)
  end

  def finish_all_transfers(attempt = 0, closing_log_id = nil)
    log_closing_step(period_expense: self, closing_log_id: closing_log_id, step_name: Constants::ClosingLog::STEPS_COLLECTION[:finish_all_transfers] + " ##{attempt}") do |closing_log|
      if bills_without_pdf.count.zero?
        # Significa que ya se procesaron todas las boletas y se puede realizar la tarea.
        # (No necesariamente están generados los pdfs)

        update(bill_generated: true, bill_generated_at: Time.now)
        transfers.order(:created_at).each(&:finish_transfer)
        return
      end

      # Si no estaban procesadas, se reencola hasta 10 veces. Quizás en la próxima ejecución estarán listos.
      if attempt == 10
        Rollbar.error('FinishAllTransfersJob se llamó 10 veces sin éxito', community_id: self.community_id, wrong_bills_ids: bills_without_pdf.ids.join(',') )
      else
        wait_time = attempt.zero? ? 5.minutes : 2.minutes
        FinishAllTransfersJob.set(wait: wait_time).perform_later(
          _community_id: community_id,
          period_expense_id: id,
          attempt: attempt + 1,
          _message: I18n.t('jobs.finish_transfers'),
          closing_log_id: closing_log_id
        )
      end
    end
  end

  def rollback_all_transfers
    self.transfers.order(:created_at).each(&:rollback)
  end

  def define_periods
    only_current_month_setting = community.get_setting_value('mes_corrido') == 1
    period_expense_ids = [self.id]
    if only_current_month_setting
      period_expense_ids << self.get_last.first.id
      period_to_assign = self
    else
      period_to_assign = self.get_next.first
    end
    [period_expense_ids, period_to_assign]
  end

  def generate_recurrent_advances
    period_expense_ids, period_to_assign = define_periods
    Advance.joins(:employee).where(period_expense_id: period_expense_ids, recurrent: true, employees: { active: true }).each do |advance|
      advance.duplicate(period_to_assign)
    end
  end

  def generate_recurrent_service_billings
    period_expense_ids, period_to_assign = define_periods
    ServiceBilling.where(period_expense_id: period_expense_ids, recurrent: true, has_fees: false).each do |service_billing|
      new_service_billing = ServiceBilling.create(
        price: 0.0, period_expense: period_to_assign, community: service_billing.community, recurrent: true,
        supplier: service_billing.supplier, name: service_billing.name, category_id: service_billing.category_id,
        paid_at: service_billing.paid_at + 1.month
      )

      if service_billing.distributed?
        service_billing.service_billing_proratables.each do |proratable|
          proratable_hash = proratable.attributes.except(*%w[id created_at updated_at service_billing_id])
          new_service_billing_meter = ServiceBillingMeter.new(proratable_hash)
          new_service_billing_meter.update(service_billing_id: new_service_billing.id)
        end
      end
    end
  end

  def close_fund_period_expenses
    community = self.community
    community.funds.each do |fund|
      previous_fund_period_expense = fund.get_previous_fund_period_expense self.id
      previous_fund_period_expense.update_fund_period_expense if previous_fund_period_expense.present?
      FundPeriodExpense.full_create(fund.id, self.id)
    end
  end

  def destroy_all_fund_period_expenses
    community = self.community
    community.funds.each do |fund|
      fund.destroy_fund_period_expense self.id
    end
  end

  def bills_without_pdf
    bills.where(bill: nil)
  end

  def short_bills_without_pdf
    bills.where(short_bill: nil)
  end

  # PDF con boletas agrupadas para los grupos y las individuales para las propiedades sin grupo
  def generate_mixed_pdf_receipts
    puts '---------------------------------------'
    puts '|INICIO GENERAR PDF BOLETAS COMBINADAS|'
    puts "|Comunidad: #{community.id} Periodo: #{id}|"
    puts '---------------------------------------'
    pdf = CombinePDF.new
    dirname = File.dirname('user_temp/period_expenses/')

    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    users = community.users.includes(account_summary_sheets: [:properties], properties: [:bills, :users, :in_charge]).distinct
    ordered_properties = []
    users.each do |user|
      # Qué pasa si primero fue agrupada y luego se desagrupó? <- tendría account_summary_sheets, primero filtrar los de este periodo
      considered_asses = user.account_summary_sheets.select { |ass| ass.period_expense_id == id }
      if considered_asses.empty?
        properties = user.properties.select { |p| p.community_id == community_id && p.person_in_charge(false) == user }
        properties = Property.sort_by_name(properties)
        properties.each do |prop|
          bill = prop.bills.detect { |prop_bill| prop_bill.period_expense_id == id }
          next unless bill.present?
          ordered_properties << PropertyStruct.new(prop.name, bill.bill.expiring_url(86400))
        end
      else
        # Find the ass for this period
        considered_asses.each do |ass|
          ordered_properties << PropertyStruct.new(Property.sort_by_name(ass.properties).first.name, ass.summary_sheet.expiring_url(86400))
        end
      end
    end
    ordered_properties = Property.sort_by_name(ordered_properties)

    ordered_properties.each do |hash|
      pdf << CombinePDF.parse(FileGetter.safe_get_file(hash[:uri_to_add]))
    end

    # Ahora pdf tiene todas las boletas
    name = "user_temp/period_expenses/mezcla_#{id}#{Time.now.to_i.to_s[6..10]}.pdf"
    pdf.save(name)
    file = File.new(name)
    self.pdf_mixed_bills = file
    save
    file.close
    File.delete(name)
    puts '------------------------------------'
    puts '|FIN GENERAR PDF BOLETAS COMBINADAS|'
    puts '------------------------------------'
  end

  def remuneration_enabled?(community)
    community.active_community_packages.exists?(package_type: 'RM') &&
      community.get_setting_value('remuneration').positive?
  end
end
