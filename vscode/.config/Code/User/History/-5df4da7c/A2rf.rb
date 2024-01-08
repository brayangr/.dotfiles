module Remuneration
  class SalaryPaymentDraftsController < ApplicationController
    load_and_authorize_resource

    def index
      @index = params[:tab] ? params[:tab].to_sym : :extra_hours

      set_filters
      set_tabs
      set_finder_params
    end

    def create
      Remuneration::SalaryPaymentDrafts::CreateResponse.call(
        community: current_community,
        create_params: create_params,
        tab: params[:tab].to_sym,
        columns: parse_columns(params, params[:tab].to_sym),
        options: { instantiate_context: self }
      )

      respond_to do |format|
        format.turbo_stream
      end
    end

    def update
      Remuneration::SalaryPaymentDrafts::UpdateResponse.call(
        community: current_community,
        salary_payment_draft: @salary_payment_draft,
        update_params: update_params,
        tab: params[:tab].to_sym,
        columns: parse_columns(params, params[:tab].to_sym),
        options: { instantiate_context: self }
      )

      respond_to do |format|
        format.turbo_stream
      end
    end

    def reset
      Remuneration::SalaryPaymentDrafts::ResetResponse.call(
        salary_payment_draft_id: reset_params[:id],
        tab: reset_params[:tab].to_sym,
        columns: parse_columns(reset_params, params[:tab].to_sym),
        user: current_user,
        options: { instantiate_context: self }
      )

      respond_to do |format|
        format.turbo_stream
      end
    end

    def bulk_reset
      Remuneration::SalaryPaymentDrafts::BulkResetResponse.call(
        community: current_community,
        user: current_user,
        tab: bulk_reset_params[:tab].to_sym,
        month: bulk_reset_params[:month],
        year: bulk_reset_params[:year],
        employee_finder: bulk_reset_params[:employee_finder],
        part_time: ActiveModel::Type::Boolean.new.cast(bulk_reset_params[:part_time]),
        options: { instantiate_context: self }
      )

      redirect_to @redirection_path, **@message
    end

    def save
      redirect_to remuneration_salary_payment_drafts_path(save_params),
                  notice: t('views.remunerations.salary_payment_drafts.success')
    end

    private

    def set_tabs
      @tabs = [
        {
          text: I18n.t('views.remunerations.salary_payment_drafts.extra_hours.title'),
          url: remuneration_salary_payment_drafts_path,
          active: @index == :extra_hours
        },
        {
          text: I18n.t('views.remunerations.salary_payment_drafts.taxable_bonus'),
          url: remuneration_salary_payment_drafts_path,
          active: @index == :taxable_bonus
        },
        {
          text: I18n.t('views.remunerations.salary_payment_drafts.worked_days.title'),
          url: remuneration_salary_payment_drafts_path(tab: :worked_days),
          active: @index == :worked_days,
          tooltip: I18n.t('views.remunerations.salary_payment_drafts.worked_days.tab_tooltip')
        },
        {
          text: I18n.t('views.remunerations.salary_payment_drafts.licenses.title'),
          url: remuneration_salary_payment_drafts_path(tab: :licenses),
          active: @index == :licenses
        },
        {
          text: I18n.t('views.remunerations.salary_payment_drafts.discounts_days'),
          url: remuneration_salary_payment_drafts_path,
          active: @index == :discounts_days
        },
        {
          text: I18n.t('views.remunerations.salary_payment_drafts.another_discounts'),
          url: remuneration_salary_payment_drafts_path,
          active: @index == :discounts
        }
      ]
    end

    def set_finder_params
      @component_attributes = {
        form: { url: remuneration_salary_payment_drafts_path },
        inputs: [
          {
            container_class: 'col-sm-3',
            options: helpers.options_for_select(select_months.map { |month| [month[:name], month[:id]] }, @month),
            attributes: { name: :month }
          },
          {
            container_class: 'col-sm-3',
            options: helpers.options_for_select(select_years(false, Date.today.year.to_i - Constants::Remunerations::MIN_YEAR_DIF).map { |year| [year[:name], year[:name]] }, @year),
            attributes: { name: :year }
          },
          {
            type: 'text',
            default_value: @employee_finder,
            container_class: 'col-sm-3',
            attributes: {
              name: :employee_finder,
              placeholder: t('views.remunerations.salary_payment_drafts.employee_finder_placeholder')
            }
          },
          {
            type: 'hidden',
            attributes: {
              name: :tab
            },
            value: @index
          }
        ],
        buttons: [
          {
            container_class: 'col-sm-3',
            type: 'submit',
            label: t(:search),
            class: 'btn btn-primary-cf btn-block'
          }
        ]
      }
    end

    def set_filters
      @payment_period_expense = current_community.get_open_period_expense
      @month = params[:month] || @payment_period_expense.period.month
      @year = params[:year] || @payment_period_expense.period.year
      @employee_finder = params[:employee_finder]
    end

    def create_params
      params.require(:salary_payment_draft).permit(
        :salary_id, :payment_period_expense_id, :worked_days, :bono_days, :creator_id,
        :extra_hour, :extra_hour_2, :extra_hour_3,
        license_drafts_attributes: %i[days start_date end_date ultimo_total_imponible_sin_licencia]
      )
    end

    def update_params
      params.require(:salary_payment_draft).permit(
        :updater_id, :worked_days, :bono_days, :extra_hour, :extra_hour_2, :extra_hour_3,
        license_drafts_attributes: %i[id days start_date end_date ultimo_total_imponible_sin_licencia _destroy]
      )
    end

    def reset_params
      params.permit(:id, :tab, :columns, :license_id)
    end

    def bulk_reset_params
      params.permit(:tab, :month, :year, :employee_finder, :part_time)
    end

    def save_params
      params.permit(:month, :year, :employee_finder, :tab)
    end

    def parse_columns(params, tab)
      JSON.parse(params[:columns], symbolize_names: true) if tab == :extra_hours
    end
  end
end
