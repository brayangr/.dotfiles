module Remunerations
  class SalaryPaymentDraftsQueries
    def self.employees(community_id:, start_date:, end_date:)
      Employee
        .joins(:salaries)
        .left_joins(:finiquitos)
        .where(community_id: community_id)
        .where('salaries.start_date <= ?', end_date)
        .where('finiquitos.end_date >= ? or finiquitos.id isnull', start_date)
        .select('employees.*, salaries.id salary_id, salaries.daily_wage daily_wage')
        .order(:father_last_name, :mother_last_name, :first_name)
    end

    def self.salary_payment_drafts(salaries_ids:, payment_period_expense_id:)
      SalaryPaymentDraft
        .where(payment_period_expense_id: payment_period_expense_id, salary_id: salaries_ids)
        .index_by(&:salary_id)
    end

    def self.last_salary_payments
      Employee
        .joins(:salaries)
        .joins(<<~SQL
          left join lateral (
            select * from salary_payments
            inner join period_expenses on period_expenses.id = salary_payments.payment_period_expense_id
            where salary_payments.salary_id = salaries.id and nullified = false and validated = true and dias_licencia = 0
            order by period_expenses.period desc
            limit 1
          ) salary_payments on salary_payments.salary_id = salaries.id
        SQL)
    end
  end
end
