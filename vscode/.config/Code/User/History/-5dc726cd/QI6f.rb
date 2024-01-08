module Remuneration
  class AdvancesController < RemunerationApplicationController
    load_and_authorize_resource

    before_action :set_advance, only: %i[update edit destroy destroy_file documentation voucher set_not_recurrent]
    before_action :set_employee, only: %i[new index create]
    before_action :set_period, only: [:edit]
    before_action :find_period_expense, only: %i[index new]
    before_action :set_create_service_billing_check_warning, only: %i[new edit]

    def new
      @advance = Advance.new(paid_at: Time.now)
      @service_billing_created = false
    end

    def create
      @advance = Advance.new(advance_params)
      @advance.creator = current_user

      period_expense = if params[:year].present? && params[:month].present?
                         current_community.get_period_expense(params[:month].to_i, params[:year].to_i)
                       else
                         current_community.get_open_period_expense
                       end
      if params[:auto_create_service_billing].present? && params[:payment_year].present? && params[:payment_month].present?
        @advance.auto_create_service_billing = params[:auto_create_service_billing]
        @advance.payment_year = params[:payment_year]
        @advance.payment_month = params[:payment_month]
        @advance.paid = params[:payment_state] == 'true'
      end
      @advance.period_expense_id = period_expense.id
      @advance.employee_id = @employee.id
      if @advance.save
        redirect_to remuneration_advances_path(employee_id: @advance.employee_id, year: @advance.period_expense.period.year,
                                              month: @advance.period_expense.period.month), notice: I18n.t('messages.notices.advance.successfully_created')
      else
        redirect_to new_remuneration_advance_path(employee_id: @advance.employee_id), alert: "<b>El registro no fue ingresado exitosamente.</b> <br> #{@advance.errors.full_messages.join('<br>')}"
      end
    end

    def index
      @recurrent_advances = params[:recurrent_advances].present?
      @advances =
        @period_expense.advances
          .preload(:period_expense, service_billing: :period_expense)
          .where(employee_id: @employee.id).order(created_at: :desc)
      @advances = @advances.where(recurrent: true) if @recurrent_advances
      @advances = @advances.paginate(page: params[:page], per_page: 30)
      set_tabs
      set_finder_params
    end

    def edit
      @employee = @advance.employee
      @service_billing_created = @advance.service_billing.present?
    end

    def update
      sso_params = {
        params: params,
        advance_params: advance_params,
        community: current_community,
        user: current_user
      }
      result = Remuneration::Advances::Updater.call(**sso_params, options: { instantiate_context: self })
      message = { result.data[:alert_type] => result.data[:alert_message] }
      redirect_to result.data[:path], **message
    end

    def set_not_recurrent
      @advance.update_columns(recurrent: false)
      advance_period = @advance.period_expense.period
      redirect_to remuneration_advances_path(employee_id: @advance.employee_id, year: advance_period.year, month: advance_period.month),
                  notice: 'El avance ya no se genera automáticamente'
    end

    def destroy
      employee_id = @advance.employee_id
      if @advance.destroy
        redirect_to remuneration_advances_path(employee_id: employee_id),
                    notice: I18n.t('views.remunerations.advances.notice.delete')
      else
        redirect_to remuneration_advances_path(employee_id: employee_id),
                    notice: I18n.t('views.remunerations.advances.notice.delete_error')
      end
    end

    def destroy_documentation
      @advance.remove_documentation!
      if @advance.save
        respond_to do |format|
          format.js
        end
      else
        respond_to do |format|
          format.js { render text: "triggerAlert('<b> No fue posible eliminar el archivo </b>')" }
        end
      end
    end

    def documentation
      redirect_to @advance.documentation.expiring_url(10)
    end

    def voucher
      redirect_to @advance.voucher.expiring_url(10)
    end

    private

    def set_advance
      @advance = current_community.advances.find(params[:id])
    end

    def set_employee
      @employee = current_community.employees.find(params[:employee_id])
    end

    def set_period
      @period_expense = current_community.get_open_period_expense
      @year = params[:year].present? ? params[:year].to_i : @period_expense.period.year
      @month = params[:month].present? ? params[:month].to_i : @period_expense.period.month
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

      @month = @period_expense.period.month unless @month
      @year = @period_expense.period.year unless @year
    end

    def advance_params
      params.fetch(:advance, {}).permit(:price, :comment, :documentation, :paid_at, :auto_create_service_billing,
                                        :payment_month, :payment_year, :recurrent, :payment_state)
    end

    def set_create_service_billing_check_warning
      @create_service_billing = current_community.get_setting_value('default_advance_behaviour') != 1

      return unless can?(:edit, current_community)
      return unless @create_service_billing

      flash.now[:warning1] = {
        message: I18n.t('messages.notices.advance.create_service_billing_check'),
        actions: [
          {
            path: edit_community_path(current_community, tab: 'remuneration'),
            title: 'editar'
          }
        ]
      }
    end

    def set_finder_params
      @component_attributes = {
        form: { url: remuneration_advances_path },
        inputs: [
          {
            type: 'month_selector',
            default_value: @month
          },
          {
            type: 'year_selector',
            default_value: @year,
            min_year: min_year
          },
          {
            type: 'hidden',
            attributes: { name: 'employee_id' },
            value: @employee.id
          }
        ],
        buttons: [
          {
            type: 'submit',
            label: I18n.t('views.commons.search'),
            class: 'btn btn-block find-btn',
            container_class: 'col-xs-12 col-sm-4'
          },
          {
            condition: can?(:create, Advance),
            class: 'btn pull-right btn-block btn-green-cf',
            container_class: 'col-xs-12 col-sm-4',
            label: I18n.t('views.remunerations.advances.new_advance'),
            icon: 'icon fa fa-plus',
            href: new_remuneration_advance_path(employee_id: @employee.id),
            attributes: {
              title: I18n.t('views.remunerations.advances.new_advance'),
              id: 'new_advance'
            }
          }
        ]
      }
    end

    def set_tabs
      @tabs = [
        {
          text: I18n.t('views.remunerations.advances.all_progress'),
          url: remuneration_advances_path(month: @period_expense.period.month, year: @period_expense.period.year, employee_id: @employee.id),
          active: !@recurrent_advances
        },
        {
          text: I18n.t('views.remunerations.advances.recurring_advances'),
          url: remuneration_advances_path(month: @period_expense.period.month, year: @period_expense.period.year, employee_id: @employee.id, recurrent_advances: true),
          active: @recurrent_advances
        }
      ]
    end
  end
end
