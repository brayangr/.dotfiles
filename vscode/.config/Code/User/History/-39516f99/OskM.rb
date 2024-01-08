module Remuneration
  module Advances
    class Updater < StandardServiceObject
      include Rails.application.routes.url_helpers

      def initialize(**sso_params)
        super

        @advance_params = sso_params[:advance_params]
        @params = sso_params[:params]
        @community = sso_params[:community]
        @user = sso_params[:user]
        @period_expense = nil
        @advance = Advance.eager_load([period_expense: :community], :service_billing, :employee).find(@params[:id]) if @params.present?
      end

      def call
        set_period_expense
        update_advance_and_service_billing_attrs
        validate_objects_and_build_response
      end

      private

      def validate_objects_and_build_response
        if @advance.valid? && advance_service_billing_valid?
          service_billing = @advance.service_billing
          ServiceBilling.skip_callback(:save, :after, :update_advance, raise: false)
          sb_changed = service_billing&.changed?
          service_billing&.save if sb_changed
          @advance.generate_voucher
          UploadAdvanceVoucherToServiceBillingJob.perform_later(
            _community_id: @community.id,
            advance_id: @advance.id,
            _message: I18n.t('messages.notices.advance.add_voucher_to_service_billing')
          )
          CommunityTransactions::Updater.call(transaction: service_billing) if sb_changed
          prepare_success_response
        else
          restore_data_and_prepare_error_response
        end
      end

      def update_advance_and_service_billing_attrs
        @advance.assign_attributes(@advance_params)
        @advance.period_expense_id = @period_expense.id
        @advance.updater = @user
        if service_billing_autocreate_and_date_present?
          assign_payment_params
          @advance.create_service_billing
        elsif @advance.service_billing.present?
          update_attr_for_associated_service_billing
        end
      end

      def set_period_expense
        @period_expense = if year_and_month_present?
                            @community.get_period_expense @params[:month].to_i,
                                                          @params[:year].to_i
                          else
                            @advance.period_expense
                          end
      end

      def advance_service_billing_valid?
        return true if @advance.service_billing&.valid? || @advance.service_billing.blank?

        @advance.errors.add(:base, I18n.t('activerecord.errors.models.advance.service_billing.unable_update', errors: @advance.service_billing.errors.full_messages.join('<br>')))
        false
      end

      def update_attr_for_associated_service_billing
        @advance.service_billing.assign_attributes(price: @advance.price, paid_at: @advance.paid_at)
      end

      def prepare_success_response
        @response.add_data(:path, remuneration_advances_path(employee_id: @advance.employee_id, year: @advance.period_expense.period.year, month: @advance.period_expense.period.month))
        if @advance_params.empty?
          @response.add_data(:alert_type, :alert)
          @response.add_data(:alert_message, I18n.t('messages.warnings.advance.upload_file'))
        else
          @response.add_data(:alert_type, :notice)
          @response.add_data(:alert_message, I18n.t('messages.notices.advance.successfully_updated'))
        end
      end

      def restore_data_and_prepare_error_response
        byebug
        @advance.restore_attributes
        @advance.service_billing.restore_attributes
        advance_period = @advance.period_expense.period
        if @advance.errors.messages[:documentation].present?
          if @advance.errors.messages[:documentation][0] == 'no es válido'
            @response.add_data(:path, edit_remuneration_advance_path(@advance, year: advance_period.year, month: advance_period.month))
            @response.add_data(:alert_type, :alert)
            @response.add_data(:alert_message, I18n.t('errors.commons.invalid_extension'))
          end
        else
          @response.add_data(:path, edit_remuneration_advance_path(@advance, year: advance_period.year, month: advance_period.month))
          @response.add_data(:alert_type, :alert)
          @response.add_data(:alert_message, I18n.t('activerecord.errors.models.advance.unable_update', errors: @advance.errors.full_messages.join('<br>')))
        end
      end

      def year_and_month_present?
        @params[:year].present? && @params[:month].present?
      end

      def service_billing_autocreate_and_date_present?
        @params[:auto_create_service_billing].present? &&
          @params[:payment_year].present? &&
          @params[:payment_month].present?
      end

      def assign_payment_params
        @advance.auto_create_service_billing = @params[:auto_create_service_billing]
        @advance.payment_year = @params[:payment_year]
        @advance.payment_month = @params[:payment_month]
      end
    end
  end
end
