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
      @salary_payment.advance_gratifications = @last_salary_payment.advance_gratifications
      @salary_payment.anual_gratifications = @last_salary_payment.anual_gratifications
      @salary_payment.bono_responsabilidad = @last_salary_payment.bono_responsabilidad

      # add custom bonus
      @salary_payment.salary_additional_infos << additional_info[:bonus].map do |bonus|
        SalaryAdditionalInfo.new(bonus.attributes.except(*EXCLUDED_ATTRIBUTES))
      end
    end

    def build_extra_hours
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_discounts
      @salary_payment.union_fee = @last_salary_payment.union_fee
      @salary_payment.legal_holds = @last_salary_payment.legal_holds

      # add custom discounts
      @salary_payment.salary_additional_infos << additional_info[:discounts].map do |bonus|
        SalaryAdditionalInfo.new(bonus.attributes.except(*EXCLUDED_ATTRIBUTES))
      end
    end

    def build_licenses
    end

    private

    def additional_info
      @additional_info ||= @last_salary_payment.salary_additional_infos.group_by do |additional_info|
        additional_info.discount? ? :discounts : :bonus
      end
    end
  end
end
