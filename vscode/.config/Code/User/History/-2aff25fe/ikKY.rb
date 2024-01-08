# frozen_string_literal: true

module Remuneration
  module SalaryPayments
    class CalculateSalary < StandardServiceObject
      def initialize(salary_payment:, run_validate: true, on_creation: false)
        super
        @salary_payment = salary_payment
        @run_validate = run_validate
        @on_creation = on_creation
      end

      def call
        pre_calculate_salary

        if @pre_calculate_salary_result.data[:salary_payment].errors.empty?
          generate_pdf
          create_salary_payment_service_billing
          update_social_credit_fees
        end

        instantiate(name: :salary_payment, data: @salary_payment)
      end

      private

      def pre_calculate_salary
        @pre_calculate_salary_result = Remuneration::SalaryPayments::PreCalculateSalary.call(
          salary_payment: @salary_payment,
          run_validate: @run_validate
        )
      end

      def generate_pdf
        @salary_payment.validated = true
        @salary_payment.generate_pdf(run_validations: @run_validate)
      end

      def create_salary_payment_service_billing
        if @salary_payment.period_expense&.persisted?
          CreateSalaryPaymentServiceBillingJob.perform_later(
            _community_id: @salary_payment.community.id,
            salary_payment_id: @salary_payment.id,
            on_creation: @on_creation,
            _message: I18n.t('jobs.create_salary_payment_service_billing')
          )
        end
      end

      def update_social_credit_fees
        social_credit_fees = @salary_payment.salary.employee.social_credit_fees.where('social_credit_fees.period_expense_id = ?', @salary_payment.payment_period_expense_id)
        social_credit_fees.update_all(employeed_paid: true) if social_credit_fees.any?
      end
    end
  end
end
