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
  end
end
