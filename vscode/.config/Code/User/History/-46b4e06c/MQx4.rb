module Remunerations
  class SalaryPaymentDraftsQueries
    def self.employees(community_id:, start_date:, end_date:)
      Employee
        .joins(:salaries)
        .left_joins(:finiquitos)
        .where(community_id: community_id, salaries: { daily_wage: true })
        .where('salaries.start_date <= ?', end_date)
        .where('finiquitos.end_date >= ? or finiquitos.id isnull', start_date)
        .select('employees.*, salaries.id salary_id')
        .order(:father_last_name, :mother_last_name, :first_name)
    end
  end
end
