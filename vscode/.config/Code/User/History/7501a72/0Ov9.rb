module Remuneration
  module SalaryPaymentDrafts
    class ResetResponse < BaseResponse
      def post_initialize
        @salary_payment_draft = SalaryPaymentDraft.find_by_id(params[:salary_payment_draft_id])
        @tab = params[:tab]
        @user = params[:user]
        @columns = params[:columns]
      end

      def call
        case @tab
        when :worked_days
          reset_worked_days
        when :extra_hours
          reset_extra_hours
        when :licenses
          reset_license
        end

        set_salary_and_employee
        instantiate_variables
      end

      private

      def reset_worked_days
        @salary_payment_draft.update(worked_days: 0, bono_days: 0, updater_id: @user.id)
      end

      def reset_extra_hours
        @salary_payment_draft.update(extra_hour: 0, extra_hour_2: 0,
                                     extra_hour_3: 0, updater_id: @user.id)
      end

      def reset_license
        @salary_payment_draft.update(updater_id: @user.id)
        @salary_payment_draft.license_drafts.destroy_all
      end
    end
  end
end
