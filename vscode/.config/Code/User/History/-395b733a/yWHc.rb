module SalaryPayments
  # Builder for a employee without draft with full time contract
  class FullTimeBuilder < BaseBuilder
    attr_reader :salary_payment

    EXCLUDED_ATTRIBUTES = %w[id salary_payment_id created_at updated_at].freeze

    def build_worked_days
      @salary_payment.worked_days = 30
    end

    def build_worked_hours; end

    def build_bonus
      return if @last_salary_payment.nil?

      # @salary_payment.advance_gratifications = @last_salary_payment.advance_gratifications
      # @salary_payment.anual_gratifications = @last_salary_payment.anual_gratifications
      # @salary_payment.bono_responsabilidad = @last_salary_payment.bono_responsabilidad

      # return unless additional_info[:bonus].present?

      # @salary_payment.salary_additional_infos << additional_info[:bonus].map do |bonus|
      #   SalaryAdditionalInfo.new(bonus.attributes.except(*EXCLUDED_ATTRIBUTES))
      # end
    end

    def build_extra_hours; end

    def build_discounts
      if @last_salary_payment.present?
        @salary_payment.union_fee = @last_salary_payment.union_fee
        @salary_payment.legal_holds = @last_salary_payment.legal_holds
      end

      @salary_payment.advance = @employee
        .advances
        .where(period_expense_id: salary_payment.payment_period_expense_id)
        .sum(:price)

      @salary_payment.ccaf = @employee
        .social_credit_fees
        .where(period_expense_id: salary_payment.payment_period_expense_id)
        .sum(:price)

      return unless additional_info[:discounts].present?

      @salary_payment.salary_additional_infos << additional_info[:discounts].map do |discount|
        SalaryAdditionalInfo.new(discount.attributes.except(*EXCLUDED_ATTRIBUTES))
      end
    end

    def build_licenses; end

    private

    def additional_info
      @additional_info ||= @last_salary_payment&.salary_additional_infos&.group_by do |additional_info|
        additional_info.discount? ? :discounts : :bonus
      end || {}
    end
  end
end
