module SalaryPayments
  class SalaryPaymentDirector
    def initialize(employee:, payment_period_expense:, period_expense: nil)
      @employee = employee
      @period_expense = period_expense
      @payment_period_expense = payment_period_expense
    end

    def self.build(employee:, payment_period_expense:, period_expense: nil)
      director = new(
        employee: employee,
        payment_period_expense: payment_period_expense,
        period_expense: period_expense
      )

      director.build
    end

    def build
      builder = initialize_builder

      return if builder.nil?

      builder.build_identification
      builder.build_worked_days
      builder.build_worked_hours
      builder.build_assignments
      builder.build_bonus
      builder.build_extra_hours
      builder.build_discounts
      builder.build_licenses
      builder.build_apv
      builder.build_partner
      builder.build_employment_protection_law
      builder.build_cash_payment

      builder.salary_payment
    end

    private

    def initialize_builder
      if salary_payment_draft.nil?
        unless salary.daily_wage
          SalaryPayments::FullTimeBuilder.new(
            employee: @employee,
            last_salary_payment: last_salary_payment,
            period_expense: @period_expense,
            payment_period_expense: @payment_period_expense,
            salary: salary
          )
        end

        # add builder for part time
      else
        # add builder with draft
      end
    end

    def salary
      @salary ||= @employee.active_salary
    end

    def last_salary_payment
      @last_salary_payment ||= @employee
        .active_salary_payments
        .joins(:payment_period_expense)
        .order('period_expenses.period desc')
        .first
    end

    def salary_payment_draft
      @salary_payment_draft ||= SalaryPaymentDraft
        .find_by(payment_period_expense: @payment_period_expense, salary: salary)
    end
  end
end
