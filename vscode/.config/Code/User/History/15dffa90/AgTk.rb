module SalaryPayments
  # Base builder for salary payments, do not use by itself if you need
  # a different behaviour implement a new concrete builder
  class BaseBuilder
    attr_reader :salary_payment

    def initialize(employee:, last_salary_payment:, period_expense:, payment_period_expense:, salary:)
      @employee = employee
      @salary_payment = SalaryPayment.new
      @last_salary_payment = last_salary_payment
      @period_expense = period_expense
      @payment_period_expense = payment_period_expense
      @salary = salary
    end

    def build_identification
      @salary_payment.salary = @salary
      @salary_payment.payment_period_expense = @payment_period_expense
      @salary_payment.period_expense = @period_expense
      @salary_payment.aliquot_id = @last_salary_payment.aliquot_id
    end

    def build_worked_days
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_worked_hours
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_assignments
      @salary_payment.allocation_tool_wear = @last_salary_payment.allocation_tool_wear
      @salary_payment.lost_cash_allocation = @last_salary_payment.lost_cash_allocation
    end

    def build_bonus
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_extra_hours
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_discounts
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_licenses
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def build_apv
      @salary_payment.apv = apv
      @salary_payment.cotizacion_empleador_apvc = employer_apvc
      @salary_payment.cotizacion_trabajador_apvc = employee_apvc
    end

    def build_partner
      return unless @last_salary_payment.spouse

      @salary_payment.spouse = @last_salary_payment.spouse
      @salary_payment.spouse_voluntary_amount = @last_salary_payment.spouse_voluntary_amount
      @salary_payment.spouse_periods_number = @last_salary_payment.spouse_periods_number
      @salary_payment.spouse_capitalizacion_voluntaria = @last_salary_payment.spouse_capitalizacion_voluntaria
    end

    def build_employment_protection_law
      return unless @last_salary_payment.employee_protection_law

      @salary_payment.employee_protection_law = @last_salary_payment.employee_protection_law
      @salary_payment.protection_law_code = @last_salary_payment.protection_law_code
      @salary_payment.suspension_or_reduction_days = @last_salary_payment.suspension_or_reduction_days
      @salary_payment.reduction_percentage = @last_salary_payment.reduction_percentage

      return if @salary_payment.protection_law_code == SalaryPayment.protection_law_codes.invert[2]

      @salary_payment.afc_informed_rent = @last_salary_payment.afc_informed_rent
    end

    def build_cash_payment
      @salary_payment.adjust_by_rounding = @last_salary_payment.adjust_by_rounding
    end


    def to_h
      {
        salary_payment: @salary_payment.attributes.compact,
        bonos:
        discounts:
      }
    end

    protected

    def apv
      return 0 if @salary.institucion_apvi == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS

      @last_salary_payment.apv
    end

    def employer_apvc
      return 0 if @salary.institucion_apvc == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS

      @last_salary_payment.cotizacion_empleador_apvc
    end

    def employee_apvc
      return 0 if @salary.institucion_apvc == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS

      @last_salary_payment.cotizacion_trabajador_apvc
    end

    def build_additional_info_data
      data = { bonus: {}, discounts: {} }
      @salary_payment.additional_salary_infos.each do |additional_info|
        if additional_info.discount
          data[:discounts] << additional_info
      end
    end
  end
end
