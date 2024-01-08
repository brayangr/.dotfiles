module Remuneration
  module SalaryPaymentDrafts
    class BulkResetResponse < StandardServiceObject
      include Rails.application.routes.url_helpers

      def post_initialize
        @community = params[:community]
        @user = params[:user]
        @tab = params[:tab]
      end

      def call
        byebug
        set_dates

        byebug
        case @tab
        when :worked_days
          @redirection_path = worked_days_remuneration_salary_payment_drafts_path
          reset_worked_days(salary_payment_drafts)
        end

        @message = { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      rescue StandardError
        @message = { alert: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.error') }
      ensure
        instantiate_variables
      end

      private

      def salary_payment_drafts
        Remunerations::SalaryPaymentDraftsQueries.salary_payment_drafts(
          salaries_ids: salaries_ids, payment_period_expense_id: @payment_period_expense.id
        )
      end

      def set_dates
        if @month.zero? && @year.zero?
          @payment_period_expense = @community.get_open_period_expense
          @month = @payment_period_expense.period.month
          @year = @payment_period_expense.period.year
        else
          @payment_period_expense = @community.get_period_expense(@month, @year)
        end

        @start_date = @payment_period_expense.period.beginning_of_month
        @end_date = @payment_period_expense.period.end_of_month
      end

      def salaries_ids
        Remunerations::SalaryPaymentDraftsQueries.employees(
          community_id: @community.id, start_date: @start_date, end_date: @end_date
        ).map(&:salary_id)
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
