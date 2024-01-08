require 'nokogiri'
module Remuneration
  class SalaryPaymentsController < RemunerationApplicationController
    include ApplicationHelper

    load_and_authorize_resource
    before_action :set_salary_payment, only: %i[show edit update nullify document pdf]
    before_action :set_salary, only: [:show, :edit, :update ]
    before_action :set_salary_id, only: [ :new, :create ]
    before_action :set_employee_id, only: [:index, :get_indicators]
    before_action :find_period_expense, only: [:new]
    before_action :fix_params, only: [:create, :update, :preview_modal]

    def index
      @salary_payments = @employee.salary_payments.includes(:period_expense).order("period_expenses.period desc")
      @salary_payments = @salary_payments.where(validated: true)
      respond_to  do |format|
        format.xlsx do
          @salary_payments = @salary_payments.where(nullified: false)
          file_excel = SalaryPayment.generate_excel(@salary_payments, current_user, @employee, current_community)
          send_data file_excel.to_stream.read, :filename => "#{I18n.t('activerecord.models.salary_payment.other').downcase} de sueldo #{@employee} (#{current_community}).xlsx", :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet"
        end
      end

    end

    # GET /salary_payments/1
    def show
      @employee = @salary_payment.employee

      respond_to do |format|
        format.html
        format.pdf do
          if @salary_payment.pdf.present?
            redirect_to @salary_payment.pdf.expiring_url(10)
          else
            service = Remuneration::SalaryPayments::PdfGenerator.call(salary_payment_id: @salary_payment.id).data
            send_data(service[:pdf].render, filename: service[:filename], type: 'application/pdf', disposition: params[:view] ? 'inline' : 'attachment')
          end
        end
      end
    end

    # GET /salary_payments/new
    def new
      @salary_payment = SalaryPayment.prepare_new(@employee, @period_expense)
      set_initial_form_values
    end

    def edit
      set_initial_form_values
      set_previous_period_expense if current_community.get_setting_value('show_information_in_the_next_period') == 1
    end

    # POST /salary_payments
    def create
      salary_payment_form = Remuneration::SalaryPaymentForm.new(attributes: {
        community: current_community,
        creator: current_user,
        employee: @employee,
        params: params,
        salary_payment_params: salary_payment_params
      }, context: self)

      if salary_payment_form.save
        redirect_to remuneration_employee_path(@employee), notice: I18n.t('notice.salary_payments.correctly_created')
      else
        response = salary_payment_form.response
        @salary_payment = salary_payment_form.salary_payment
        @month = response.data[:month]
        @year = response.data[:year]
        @salary_month = response.data[:salary_month]
        @salary_year = response.data[:salary_year]
        @aliquots = response.data[:aliquots]
        @create_service_billing = response.data[:create_service_billing]
        @bonos = response.data[:bonos]
        @discounts = response.data[:discounts]
        @payment_period_expense = response.data[:payment_period_expense]

        set_bonus_factor

        render :new
      end
    end

    def create_massive
      params = create_massive_params

      payment_period = "#{params[:payment_period_expense_year]}-#{params[:payment_period_expense_month]}-01"
      payment_period_expense = current_community.period_expenses.find_by(period: payment_period)

      period = "#{params[:period_expense_year]}-#{params[:period_expense_month]}-01"
      period_expense = params[:generate_period_expense] == 1 ? current_community.period_expenses.find_by(period: period) : nil

      GenerateSalaryPaymentsJob.perform_later(
        _community_id: current_community.id,
        payment_period_expense_id: payment_period_expense.id,
        period_expense_id: period_expense&.id
      )

      redirect_to remuneration_employees_path(
        month: params[:payment_period_expense_month],
        year: params[:payment_period_expense_year]
      )
    end

    def update
      sp_saved = false
      ActiveRecord::Base.transaction do
        @salary_payment.updater = current_user

        if @salary_payment.payment_period_expense_id
          social_credit = @salary.employee.social_credit_fees.where("social_credit_fees.period_expense_id = ?", @salary_payment.payment_period_expense_id )
          social_credit.update_all(employeed_paid: false) if social_credit.any?
        end

        ## set values by params
        set_first_salary_payment_values(params: params, is_preview: false)
        if !@salary_payment.errors.any?
          @salary_payment.assign_attributes(update_salary_payment_params)
          set_salary_payment_values_pre_calculate(params: params, is_preview: false)
          sp_saved = @salary_payment.save
        end

        raise ActiveRecord::Rollback unless sp_saved
      end

      if sp_saved
        Remuneration::SalaryPayments::CalculateSalary.call(salary_payment: @salary_payment)

        redirect_to remuneration_employee_path(@employee), notice: I18n.t('messages.notices.salary_payments.update')
      else
        error_msg = I18n.t('messages.errors.salary_payments.update_error').html_safe
        @salary_payment.errors.full_messages.each{ |msg| error_msg += "<li>#{msg}</li>" }
        error_msg += '</ul>'

        redirect_to edit_remuneration_salary_payment_path(@salary_payment), alert: error_msg
      end
    end

    # GET /payment/:id/nullify
    def nullify
      if @salary_payment&.period_expense&.common_expense_generated && current_community.get_setting_value('incomes_and_outcomes_in_closed_periods').zero?
        return redirect_to remuneration_employee_path(@employee), notice: "#{I18n.t('views.common_expenses.conjuntion.the.one').capitalize} #{I18n.t('views.common_expenses.one').downcase} ya fue cerrado, la #{I18n.t('activerecord.models.salary_payment.one').downcase} no se puede anular."
      end
      if @salary_payment.nullify! current_date, false, current_user
        redirect_to remuneration_employee_path(@employee), notice: "La #{I18n.t('activerecord.models.salary_payment.one').downcase} fue exitosamente anulada."
      else
        flash[:alert] = t(:could_not_nullify, scope: %i[messages errors salary_payments])
        redirect_to remuneration_employee_path(@employee)
      end
    end

    def get_indicators
      if params[:year].present? && params[:month].present?
        @period_expense = current_community.get_period_expense(params[:month].to_i, params[:year].to_i)
      else
        @period_expense = current_community.get_open_period_expense
      end
      @advance = @employee.advances.where(period_expense_id: @period_expense.id).sum(:price)
      @ccaf = @employee.social_credit_fees.where(period_expense_id: @period_expense.id).sum(:price)
      set_bonus_factor
      respond_to do |format|
        format.js
      end
    end

    def details
      set_salary_payment
      @employee = @salary_payment.employee
      @period_expense = @salary_payment.payment_period_expense
      @library_response = JSON.parse(@salary_payment.library_response)
    end

    def document
      redirect_to @salary_payment.document.expiring_url(10)
    end

    def pdf
      redirect_to @salary_payment.pdf.expiring_url(10)
    end

    def upload_document
      if @salary_payment.update(update_document_params)
        redirect_to params[:come_back_to], notice: I18n.t('messages.notices.salary_payments.voucher_upload')
      else
        redirect_to params[:come_back_to], alert: list_errors(title: I18n.t('messages.errors.salary_payments.voucher_upload'), messages: @salary_payment.errors.full_messages)
      end
    end

    def preview_modal
      @last_previred_date = PreviredScraper.order(date: :desc).first.date
      @salary_period = Date.new(params[:salary_year].to_i, params[:salary_month].to_i)
      if (@last_previred_date < @salary_period) && !salary_payment_params[:use_last_previred_data].eql?('true')
        respond_to do |format|
          @show_previred_warning = true
          format.js
        end
      else
        @employee = Employee.joins(:community).where(community_id: current_community.id, id: params[:employee_id]).first
        @salary = Salary.joins(:employee).where(employee_id: @employee.id, id: params[:salary_id]).first
        @salary_payment = @employee.salary_payments.where(nullified: false, validated: false).first_or_initialize
        @salary_payment.assign_attributes(salary_payment_params)
        ## set params values
        set_first_salary_payment_values(params: params, is_preview: true)
        set_salary_payment_values_pre_calculate(params: params, is_preview: true) unless @salary_payment.errors.any?
        set_bonus_factor
        @salary_payment.errors.add(:base, :no_scraper_data) if @previred.blank?
        if @salary_payment.errors.none?
          respond_to do |format|
            @negative_liquid_total = @salary_payment.total_liquido_a_pagar.to_f.negative?
            format.js
          end
        else
          respond_to do |format|
            format.js
            format.json { render json: @salary_payment.errors, status: :unprocessable_entity }
          end
        end
      end
    end

    def set_first_salary_payment_values(params:, is_preview: false)
      @salary_payment.salary_id = @salary.id
      @salary_payment.community ||= current_community
      @service_billing_in_salary_payments_setting = current_community.get_setting_value('service_billing_in_salary_payments')

      if @salary.employee.active_salary.daily_wage && params[:salary_payment][:worked_days].to_i.zero?
        @salary_payment.errors.add(:base, :worked_days_cannot_be_zero)
      end

      if params[:salary_payment][:employee_protection_law] == "true" && !params[:salary_payment][:protection_law_code].present?
        @salary_payment.errors.add(:base, :protection_law_code_not_be_blank)
      end

      salary_start_date = @salary.employee.active_salary.start_date
      @part_time_worker = @salary.employee.active_salary.daily_wage
      worked_days =
        if @part_time_worker
          params[:salary_payment][:worked_days].to_i
        elsif params[:salary_month].to_i == salary_start_date.month && params[:salary_year].to_i == salary_start_date.year
          30 - (salary_start_date.day - 1)
        else
          30
        end

      if params[:salary_payment][:employee_protection_law] == 'true' && params[:salary_payment][:protection_law_code].present?
        discount_days = params[:salary_payment][:dias_licencia].to_i + params[:salary_payment][:discount_days].to_i + params[:salary_payment][:suspension_or_reduction_days].to_i
        message = :worked_days_cannot_be_less_than_discounted_with_suspension
      else
        discount_days = params[:salary_payment][:dias_licencia].to_i + params[:salary_payment][:discount_days].to_i
        message = :worked_days_cannot_be_less_than_discounted
      end

      @total_worked_days = worked_days - discount_days
      # los dias descontados y de licencia no pueden ser mayores a los dias trabajados
      @salary_payment.errors.add(:base, message) if @total_worked_days.negative?

      if @salary_payment.spouse
        @salary_payment.spouse_capitalizacion_voluntaria = params[:salary_payment][:spouse_capitalizacion_voluntaria]
        @salary_payment.spouse_voluntary_amount = params[:salary_payment][:spouse_voluntary_amount]
        @salary_payment.spouse_periods_number = params[:salary_payment][:spouse_periods_number]
      end

      # Ley de proteccion del empleado
      if @salary_payment.employee_protection_law
        @salary_payment.reduction_percentage = 0 if @salary_payment.protection_law_code != 'reduccion_jornada_laboral'
      end

      # Salary message
      if params[:salary_payment][:salary_attributes][:payment_message].present?
        @salary_payment.salary.payment_message = params[:salary_payment][:salary_attributes][:payment_message]
      end

      # Validacion de dias licencia, descuento y trabajado que no pueden ser menor a 0
      @salary_payment.errors.add(:dias_licencia, :greater_than_or_equal_to_zero) if @salary_payment.dias_licencia.to_i < 0
      @salary_payment.errors.add(:worked_days, :greater_than_or_equal_to_zero)   if @salary_payment.worked_days.to_i   < 0
      @salary_payment.errors.add(:discount_days, :greater_than_or_equal_to_zero) if @salary_payment.discount_days.to_i < 0


      # Si hay dias de licencia el ultimo total imponible no puede ser 0
      if (@salary_payment.dias_licencia &.> 0) && (@salary_payment.ultimo_total_imponible_sin_licencia &.<= 0)
        @salary_payment.errors.add(:ultimo_total_imponible_sin_licencia, :zero)
      end

      # Si el codigo seleccionado para la ley es 13 o 14 ultimo total imponible no puede ser 0
      if (@salary_payment.protection_law_code_is_13_or_14?) && (@salary_payment.ultimo_total_imponible_sin_licencia &.<= 0)
        @salary_payment.errors.add(:ultimo_total_imponible_sin_licencia, :cannot_be_zero_with_suspension_days)
      end

      # Si el codigo seleccionado para la ley es 13 o 14 Renta informada en AFC para el cálculo de la AFP y SIS no puede ser 0
      if (@salary_payment.protection_law_code_is_13_or_14?) && (@salary_payment.afc_informed_rent.to_f &.<= 0)
        @salary_payment.errors.add(:afc_informed_rent, :cannot_be_zero_with_suspension_days)
      end

      # PERÍODO DEL SALARIO
      if params[:salary_year].present? && params[:salary_month].present?
        params_payment_period_expense = current_community.get_period_expense(params[:salary_month].to_i, params[:salary_year].to_i)
        if (params_payment_period_expense.period < @employee.active_salary.start_date.at_beginning_of_month) && !is_preview
          @salary_payment.errors.add(:payment_period_expense, :invalid)
        else
          @salary_payment.payment_period_expense_id = params_payment_period_expense.id
        end
      else
        payment_date = [@employee.active_salary.start_date, current_community.get_open_period_expense.period].max
        @salary_payment.payment_period_expense_id = @employee.community.get_period_expense(payment_date.month, payment_date.year).id
      end

      # PERIOD EXPENSE A COBRAR
      if @service_billing_in_salary_payments_setting != 1 && params[:auto_create_service_billing].present?
        if params[:year].present? && params[:month].present?
          @period_expense = current_community.get_period_expense(params[:month].to_i, params[:year].to_i)
        else
          @period_expense = current_community.get_open_period_expense
        end

        show_in_next_period = current_community.get_setting_value('show_information_in_the_next_period') == 1
        @period_expense = show_in_next_period ? @period_expense.get_next.first : @period_expense

        @salary_payment.period_expense_id = @period_expense.id
      end

      @salary_payment.validate_no_closed_period

      #agregar información adicional, eliminando la anterior
      @salary_payment.salary_additional_infos.destroy_all
      params[:discounts].to_unsafe_h.except("{index}").values.select { |d| (d[:value].to_i > 0) && !d[:name].empty? }.each do |p|
        p['discount'] = true
        @salary_payment.salary_additional_infos << SalaryAdditionalInfo.new(p)
      end
      params[:bonos].to_unsafe_h.except('{index}').values.select { |bono| bono[:value].to_i.positive? && !bono[:name].empty? }.each do |bono_params|
        bono_params.delete(:post_tax_value)
        bono_params[:post_tax] = bono_params[:post_tax] == 'true'
        @salary_payment.salary_additional_infos << SalaryAdditionalInfo.new(bono_params)
      end

      salary_payment_in_period = @employee.active_salary_payments.joins('join period_expenses on period_expenses.id = payment_period_expense_id').select('period_expenses.period').where('extract(month from period_expenses.period) = ? and extract(year from period_expenses.period) = ?', params[:salary_month], params[:salary_year]).any?
      if salary_payment_in_period && params[:salary_payment_id].blank? && @salary_payment.id.blank?
        @salary_payment.errors.add(:base, :already_generated_for_period)
      end

      unless @salary.employee.active_salary.daily_wage
        salary_start_date = @salary.employee.active_salary.start_date
        # Check if the salary payment is done in the same month than the contract initial date
        if params[:salary_month].to_i == salary_start_date.month && params[:salary_year].to_i == salary_start_date.year
          @salary_payment.worked_days = 30 - (salary_start_date.day - 1)
        end
      end
    end

    def set_bonus_factor
      @payment_period_expense ||= @salary_payment&.payment_period_expense || current_community.get_period_expense(params[:month].to_i, params[:year].to_i)
      @previred = PreviredScraper.get_data_for_remuneration(date: @payment_period_expense.period, return_last: true)
      @salary ||= @salary || @employee.active_salary
      if @previred.present?
        @afp_factor = @salary.has_afp ? (@previred.dig('AFP', @salary.afp&.downcase, 'tasa_afp').to_f || 0) / 100 : 0
        @afc_factor =
          if @payment_period_expense.present? && @salary.has_seguro_cesantia && @salary.contract_type == 'Indefinido' && @salary.less_than_11_years(@payment_period_expense.period.end_of_month)
            (@previred.dig('SEGURO_CESANTIA', 'contrato_indefinido', 'trabajador').to_f || 0) / 100
          else
            0
          end
        @health_factor = @salary.has_isapre ? CalculateSalary::FONASA_PERCENTAGE : 0
        @bonus_factor = 1 - (@afp_factor + @afc_factor + @health_factor)
      else
        @afp_factor = 0
        @afc_factor = 0
        @health_factor = 0
        @bonus_factor = 1
      end
    end

    def set_salary_payment_values_pre_calculate(params:, is_preview: false)
      delete_duplicated_salary_payments unless is_preview
      pre_calculate_salary_result = Remuneration::SalaryPayments::PreCalculateSalary.call(salary_payment: @salary_payment, preview: is_preview)
      result = pre_calculate_salary_result.data[:calculate_salary_result]
      @salary_payment.advance = @salary_payment.employee.advances.where(period_expense_id: @salary_payment.payment_period_expense_id).sum(:price)
      # si es un arreglo significa que hubo un error por lo cual regresa un arreglo de los mensajes de error.
      if pre_calculate_salary_result.data[:salary_payment].errors.any?
        ## render a edit porque en pre_calculate_salary si el preview es falso, se hace save del salary_payment
        result = pre_calculate_salary_result.data[:salary_payment].errors
        render :edit, alert: result[0].capitalize unless is_preview
      else
        @haberes = result["haberes"]
        @haberes_no_imponibles = result["haberes_no_imponibles"]
        @descuentos_imponibles = result["descuentos_imponibles"]
        @descuentos = result["descuentos"]
        @otros_descuentos = result["otros_descuentos"]
        @employee = @salary_payment.employee
        @community = @salary_payment.employee.community
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def delete_duplicated_salary_payments
      Remuneration::FilterSalaryPayments.call(
        community: current_community,
        employee: @employee,
        month: @period_expense&.period&.month,
        year: @period_expense&.period&.year
      )
    end

    def set_salary_payment
      # @salary_payment = SalaryPayment.find(params[:id])
      @salary_payment = current_community.salary_payments.find(params[:id])
      @employee = @salary_payment.employee
    end

    def set_salary
      @salary = @salary_payment.salary
      @employee = @salary.employee
    end

    def set_salary_id
      @salary = current_community.salaries.includes(:employee).where('salaries.id = ?', params[:salary_id]).first
      @employee = @salary.employee
    end

    def set_employee_id
      @employee = current_community.employees.find(params[:employee_id])
    end

    def set_initial_form_values
      # PERIODO DE LA LIQUIDACION DE SUELDO
      @payment_period_expense = @salary_payment.payment_period_expense
      @salary_month = params[:month] || @payment_period_expense&.period&.month
      @salary_year = params[:year] || @payment_period_expense&.period&.year

      # PERIOD EXPENSE A COBRAR
      @period_expense = @salary_payment&.period_expense
      @month = @period_expense&.period&.month
      @year = @period_expense&.period&.year

      @aliquots = current_community.aliquots
      @service_billing_in_salary_payments_setting = current_community.get_setting_value('service_billing_in_salary_payments')
      @create_service_billing = @service_billing_in_salary_payments_setting != 1
      @employee_name = @employee.full_name

      # BONOS AND DISCOUNTS
      @bonos = @salary_payment.salary_additional_infos.reject(&:discount)
      @discounts = @salary_payment.salary_additional_infos.select(&:discount)
      set_bonus_factor
    end

    def find_period_expense
      if params[:month].present? && params[:year].present?
        @month = params[:month].to_i
        @year = params[:year].to_i
        @period_expense = current_community.get_period_expense(@month, @year, false)
      elsif current_community.get_setting_value('mes_corrido') == 1
        @period_expense = current_community.last_closed_period_expense
      else
        @period_expense = current_community.get_open_period_expense
      end

      @month ||= @period_expense.period.month
      @year ||= @period_expense.period.year
    end

    def set_previous_period_expense
      @period_expense = @period_expense.get_last.first
      @month = @period_expense&.period&.month
      @year = @period_expense&.period&.year
    end

    # Only allow a trusted parameter "white list" through.
    def salary_payment_params
      params
        .require(:salary_payment)
        .permit(:ultimo_total_imponible_sin_licencia, :carga_familiar_retroactiva, :worked_days, :extra_hour_3, :extra_hour_2,
                :bono_days, :otros_bonos_imponible, :dias_licencia, :bono_responsabilidad, :discount_hours, :deposito_convenido,
                :tipo_apv, :extra_hour, :discount_days, :advance_gratifications, :apv, :special_bonus, :refund, :viaticum,
                :lost_cash_allocation, :allocation_tool_wear, :additional_hour_price, :union_fee, :legal_holds, :aliquot_id, :mutual,
                :commision, :cotizacion_trabajador_apvc, :cotizacion_empleador_apvc, :renta_imponible_sustitutiva,
                :anual_gratifications, :spouse, :adjust_by_rounding, :protection_law_code, :employee_protection_law,
                :reduction_percentage, :suspension_or_reduction_days, :afc_informed_rent, :nursery, :aguinaldo, :union_pay, :home_office,
                :use_last_previred_data,
                salary_attributes: [:payment_message])
    end

    def update_salary_payment_params
      params
        .require(:salary_payment)
        .permit(:ultimo_total_imponible_sin_licencia, :carga_familiar_retroactiva, :worked_days, :extra_hour_3, :extra_hour_2,
                :bono_days, :otros_bonos_imponible, :dias_licencia, :bono_responsabilidad, :discount_hours, :deposito_convenido,
                :tipo_apv,:extra_hour, :discount_days, :advance_gratifications, :apv, :special_bonus, :refund, :viaticum,
                :lost_cash_allocation, :allocation_tool_wear, :additional_hour_price, :union_fee, :legal_holds, :aliquot_id, :mutual,
                :commision, :cotizacion_trabajador_apvc, :cotizacion_empleador_apvc, :renta_imponible_sustitutiva,
                :anual_gratifications, :spouse, :adjust_by_rounding, :protection_law_code, :employee_protection_law,
                :reduction_percentage, :suspension_or_reduction_days, :afc_informed_rent, :nursery, :aguinaldo, :union_pay, :home_office, :use_last_previred_data,
                salary_attributes: %i[payment_message id])
    end

    def fix_params
      if params["salary_payment"]["employee_protection_law"] != "true"
        params["salary_payment"]["protection_law_code"] = nil
        params["salary_payment"]["suspension_or_reduction_days"] = 0
        params["salary_payment"]["reduction_percentage"] = nil
        params["salary_payment"]["afc_informed_rent"] = nil
      end
    end

    def update_document_params
      params.require(:salary_payment).permit(:document)
    end

    def create_massive_params
      params.permit(:payment_period_expense_month, :payment_period_expense_year,
                    :period_expense_month, :period_expense_year, :generate_period_expense)
    end
  end
end
