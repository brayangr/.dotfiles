module Remuneration
  module SalaryPaymentDrafts
    class IndexResponse < StandardServiceObject
      def post_initialize
        @community = params[:community]
        @employee_finder = params[:employee_finder]
        @month = params[:month].to_i
        @year = params[:year].to_i
        @part_time = params[:part_time] || false
        @order = params[:order] || 'asc'
        @tab = params[:tab] || :extra_hours
      end

      def call
        set_dates
        set_employees
        filter_part_time if @part_time
        filter_employees if @employee_finder.present?
        desc_order if @order == 'desc'
        set_salaries
        set_salary_payment_drafts
        set_partial
        set_last_salary_payments if @tab == :licenses
        instantiate_variables
      end

      private

      def salaries_ids
        @salaries_ids ||= @employees.map(&:salary_id)
      end

      def set_dates
        if @month.zero? && @year.zero?
          @payment_period_expense = @community.get_open_period_expense
          @month = @payment_period_expense.period.month
          @year = @payment_period_expense.period.year
        else
          @payment_period_expense = @community.get_period_expense(@month, @year)
        end

        @start_date = @payment_period_expense.period.beginning_of_month
        @end_date = @payment_period_expense.period.end_of_month
      end

      def set_employees
        @employees = Remunerations::SalaryPaymentDraftsQueries.employees(
          community_id: @community.id, start_date: @start_date, end_date: @end_date
        )
      end

      def filter_part_time
        @employees = @employees.where(id: @employees.select(&:daily_wage).map(&:id))
      end

      def filter_employees
        value = @employee_finder.to_s.split(' ').map { |e| e.mb_chars.unicode_normalize(:nfkd).gsub(/[^.\/\-x00-\x7F]/n, '').to_s.downcase }.join(' ')
        params = [
          'employees.first_name',
          'employees.father_last_name',
          'employees.mother_last_name',
          "concat(employees.first_name, ' ', employees.father_last_name)",
          "concat(employees.first_name, ' ', employees.father_last_name, ' ', employees.mother_last_name)",
          "concat(employees.father_last_name, ' ', employees.mother_last_name)"
        ]

        query = params.map { |p| "unaccent(lower(#{p})) ilike '%#{value}%'" }.join(' or ')
        @employees = @employees.where(query)
      end

      def desc_order
        @employees = @employees.reverse
      end

      def set_salaries
        @salaries = Salary
          .where(id: salaries_ids)
          .index_by(&:employee_id)
      end

      def set_salary_payment_drafts
        @salary_payment_drafts = Remunerations::SalaryPaymentDraftsQueries.salary_payment_drafts(
          salaries_ids: salaries_ids, payment_period_expense_id: @payment_period_expense.id
        )
      end

      def set_partial
        @partial = "async/remunerations/#{@tab}_table"
      end

      def set_last_salary_payments
        @last_salary_payments = {}
        @employees.each do |employee|
          byebug
          liquidacion_sin_licencia = employee.salary_payments.where(nullified: false, validated: true, dias_licencia: 0).joins(:payment_period_expense).order('period_expenses.period desc').first

          last_salary_payment = liquidacion_sin_licencia.present? ? liquidacion_sin_licencia.total_imponible : 0

          @last_salary_payments[employee.id] = last_salary_payment
        end
      end

      def instantiate_variables
        @response.add_data(:payment_period_expense, @payment_period_expense, instantiable: true)
        @response.add_data(:month, @month, instantiable: true)
        @response.add_data(:year, @year, instantiable: true)
        @response.add_data(:employee_finder, @employee_finder.to_s, instantiable:true)
        @response.add_data(:employees, @employees, instantiable: true)
        @response.add_data(:salaries, @salaries, instantiable: true)
        @response.add_data(:salary_payment_drafts, @salary_payment_drafts, instantiable: true)
        @response.add_data(:order, @order, instantiable: true)
        @response.add_data(:partial, @partial, instantiable: true)
        @response.add_data(:tab, @tab, instantiable: true)
        @response.add_data(:last_salary_payments, @last_salary_payments, instantiable: true) if @tab == :licenses
      end
    end
  end
end
