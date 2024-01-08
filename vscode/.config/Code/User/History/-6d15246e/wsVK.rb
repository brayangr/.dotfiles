class GenerateSalaryPaymentsJob < CustomJob
  queue_as :high_ram_queue

  # community_id siempre va con _ ?
  def perform(_community_id: nil, payment_period_expense_id: nil, period_expense_id: nil, _message: I18n.t('jobs.generate_salary_payments_job'))
    return if _community_id.nil? || payment_period_expense_id.nil?

    community = Community.find(_community_id)
    payment_period_expense = community.period_expenses.find(payment_period_expense_id)
    period_expense = period_expense.present? ? community.period_expenses.find(period_expense_id) : nil

    employees = Remunerations::SalaryPaymentDraftsQueries.employees(
      community_id: community.id,
      start_date: payment_period_expense.period.beginning_of_month,
      end_date: payment_period_expense.period.end_of_month
    )

    # Todo o nada!!!!
    employees.each do |employee|
      p "empleado #{employee.id}"
      salary_payment = SalaryPayments::SalaryPaymentDirector.new(
        employee: employee,
        payment_period_expense: payment_period_expense,
        period_expense: period_expense
      )

      byebug
      salary_payment.valid?
    end
  rescue ActiveRecord::RecordNotFound => e
    raise e
    # Mensaje de error
  end
end
