module SalaryPayments
  # Builder for a employee without draft with full time contract
  class FullTimeBuilder < BaseBuilder
    attr_reader :salary_payment

    EXCLUDED_ATTRIBUTES = %w[id salary_payment_id created_at updated_at].freeze

    def build_identification
      @salary_payment.salary = @salary
      @salary_payment.payment_period_expense = @payment_period_expense
      @salary_payment.period_expense = @period_expense
      @salary_payment.aliquot_id = @last_salary_payment.aliquot_id
    end

    def build_worked_days
      @salary_payment.worked_days = 30
    end

    def build_worked_hours
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_bonus

      # add custom bonus
      @salary_payment.salary_additional_infos << additional_info[:bonus].map do |bonus|
        SalaryAdditionalInfo.new(bonus.attributes.except(*EXCLUDED_ATTRIBUTES))
      end
    end

    def build_extra_hours
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_discounts

      # add custom discounts
      @salary_payment.salary_additional_infos << additional_info[:discounts].map do |bonus|
        SalaryAdditionalInfo.new(bonus.attributes.except(*EXCLUDED_ATTRIBUTES))
      end
    end

    def build_licenses
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    private

    def additional_info
      @additional_info ||= @last_salary_payment.salary_additional_infos.group_by do |additional_info|
        additional_info.discount? ? :discounts : :bonus
      end
    end
  end
end
