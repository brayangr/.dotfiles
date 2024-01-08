module Remuneration
  module Employees
    class PreviredGetter < ApplicationService
      def initialize(com, pe)
        @community                                = com
        @employees                                = @community.employees
        @employee_ids                             = @employees.pluck(:id)
        @period_expense_id                        = pe.id
      end

      def call
        previred_for_each_employee(social_credits_fees_with_community_ccaf, social_credits_fees_with_other_ccaf)
      end

      private

      # por cada crédito equivalente a la caja de la comunidad
      def social_credits_fees_with_community_ccaf
        sql_same_ccaf = RemunerationQueries.social_credits_fees_with_community_ccaf_by_employee(@community, @employee_ids, @period_expense_id)
        sums = ActiveRecord::Base.connection.execute(sql_same_ccaf)
        sums.map { |e| [e['employee_id'], e['sum_price']] }.to_h
      end

      # por cada crédito distinto a la caja de la comunidad
      def social_credits_fees_with_other_ccaf
        sql_other_ccaf = RemunerationQueries.social_credits_fees_with_other_ccaf_by_employee(@community, @employee_ids, @period_expense_id)
        sums_other_ccaf = ActiveRecord::Base.connection.execute(sql_other_ccaf)
        sums_grouped = sums_other_ccaf.group_by { |d| d['employee_id'] }
        sums_grouped.map { |f| [f[0], f[1].map { |e| [e['supplier'], e['sum_price']] }.to_h] }.to_h
      end

      def previred_for_each_employee(social_credit_fees_by_employee_id, other_social_credit_fees_by_employee_id)
        previred = []
        active_salary_payments = @community.salary_payments
                                           .valid_and_not_nullified
                                           .eager_load(:employee, :payment_period_expense, salary: [:community])
                                           .where(payment_period_expense_id: @period_expense_id)
                                           .group_by(&:employee)
        @employees.each do |employee|
          salary_payment = active_salary_payments[employee]&.first
          next if salary_payment.nil?

          previred << Previred.previred_lines(salary_payment, social_credit_fees_by_employee_id[employee.id], other_social_credit_fees_by_employee_id[employee.id])
        end
        previred
      end
    end
  end
end
