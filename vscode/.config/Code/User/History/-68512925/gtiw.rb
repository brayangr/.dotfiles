module Remuneration
  module SalaryPaymentDrafts
    class BulkResetResponse < IndexResponse
      include Rails.application.routes.url_helpers

      def post_initialize
        super

        @user = params[:user]
        @tab = params[:tab]
      end

      def call
        set_dates
        set_employees
        filter_part_time if @part_time
        filter_employees if @employee_finder.present?
        desc_order if @order == 'desc'
        set_salaries
        set_salary_payment_drafts

        case @tab
        when :worked_days
          reset_worked_days(@salary_payment_drafts)
        when :extra_hours
          reset_extra_hours(@salary_payment_drafts)
        end

        @redirection_path = remuneration_salary_payment_drafts_path(filter_params)

        @message = { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      rescue StandardError
        @message = { alert: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.error') }
      ensure
        instantiate_variables
      end

      private

      def filter_params
        { month: @month, year: @year, employee_finder: @employee_finder, tab: @tab }
      end

      def prepare_data(salary_payment_drafts)
        salary_payment_drafts.map do |_id, salary_payment_draft|
          yield salary_payment_draft

          salary_payment_draft.updater_id = @user.id
          salary_payment_draft
        end
      end

      def reset_worked_days(salary_payment_drafts)
        data = prepare_data(salary_payment_drafts) do |salary_payment_draft|
          salary_payment_draft.worked_days = 0
          salary_payment_draft.bono_days = 0
        end

        reset!(data, %i[worked_days bono_days updater_id])
      end

      def reset_extra_hours(salary_payment_drafts)
        data = prepare_data(salary_payment_drafts) do |salary_payment_draft|
          salary_payment_draft.extra_hour = 0
          salary_payment_draft.extra_hour_2 = 0
          salary_payment_draft.extra_hour_3 = 0
          salary_payment_draft.extra_hour_3 = 0
          salary_payment_draft.bono_days = 0
        end

        reset!(data, %i[extra_hour extra_hour_2 extra_hour_3 updater_id bono_days])
      end

      def reset!(data, keys_to_update)
        SalaryPaymentDraft.import!(data, on_duplicate_key_update: keys_to_update)
      end

      def instantiate_variables
        @response.add_data(:redirection_path, @redirection_path, instantiable: true)
        @response.add_data(:message, @message, instantiable: true)
      end
    end
  end
end
