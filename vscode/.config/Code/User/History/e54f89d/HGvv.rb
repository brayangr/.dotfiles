module Remuneration
  module Employees
    class LreGetter < ApplicationService
      def initialize(community_id:, month:, year:, user_id:)
        @month = month.to_i
        @year = year.to_i
        @employees = set_data(community_id, month, year)
        @community_id = community_id
        @user_id = user_id
      end

      def call
        validation_result = validate_data
        return { result: false, errors: validation_result } if validation_result.length.positive?

        generate_document
      end

      def generate_document
        lre = [Lre.headers]
        @employees.each do |employee|
          row = []
          Lre::HEADER_CODES.each { |key, _value| row << employee[key].to_s }
          lre << row.join(';')
        end
        { result: true, data: lre }
      end

      def set_data(community_id, month, year)
        constants = Lre.set_constants
        employees_data = LreQuery.employees(community_id, month, year)
        community_employees_ids = employees_data.map { |row| row['1000'] }
        community_employees = Employee.where(id: community_employees_ids)
        community = Community.find_by(id: community_id)
        period_expense = community.get_period_expense(@month, @year)

        employees_data.map do |employee|
          current_employee = community_employees.detect { |ce_obj| ce_obj.id == employee['1000'] }
          get_payment_sis_data(employee, current_employee, period_expense.id)
          not_calculated_data = format_not_calculated_data(employee, community)
          calculated_data = add_calculated_fields(employee)
          not_calculated_data.merge(calculated_data).merge(constants)
        end
      end

      def get_payment_sis_data(employee, current_employee, period_expense_id)
        salary_payment = current_employee.salary_payments.find_by(payment_period_expense_id: period_expense_id, nullified: false)
        employee['4155'] = salary_payment&.get_payment_sis(current_employee) || 0
      end

      def format_not_calculated_data(employee, community)
        employee = employee.transform_keys(&:to_i)
        library_response = JSON.parse(employee[-9999])

        # data from salary 'screenshot'
        salary_params = library_response['params']
        employee[1102] = salary_params['salary_start_date'].to_date.strftime('%d/%m/%Y')
        employee[1107] = salary_params['daily_wage'] ? 201 : 101
        employee[1108] = salary_params['person_with_disabily'] || 0
        employee[1109] = [1, 2].include?(salary_params['tipo_empleado']) && salary_params['person_with_disability']&.zero? ? 1 : 0
        employee[1111] = salary_params['number_of_loads'] || 0
        employee[1112] = salary_params['mothernal_number_of_loads']&.positive? ? 1 : 0
        employee[1113] = salary_params['invalid_number_of_loads'] || 0
        employee[1118] = salary_params['subsidy_young_worker'] ? 1 : 0
        employee[1141] = format_code(salary_params['afp'], 'afp_codes')
        employee[1142] = salary_params['has_ips'] ? salary_params['ex_caja_regimen'] : 0
        employee[1142] = format_code(employee[1142], 'ips_codes') unless employee[1142].is_a? Integer
        employee[1143] = salary_params['isapre'] == 'Isapre de Codelco Ltda.' ? salary_params['isapre_codelco'] || 'Chuquicamata' : salary_params['isapre']
        employee[1151] = salary_params['has_seguro_cesantia'] ? 1 : 0
        employee[1152] = salary_params['mutual'] || community.mutual || 'Sin Mutual'
        employee[1155] = salary_params['institucion_apvi'].nil? || salary_params['institucion_apvi'] == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS ? 0 : 1
        employee[1157] = salary_params['institucion_apvc'].nil? || salary_params['institucion_apvc'] == Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS ? 0 : 1

        not_permitted_causales = [0, 1, 2]
        employee[1104] = employee[1104].present? && not_permitted_causales.exclude?(employee[1104]) ? employee[1104] : nil
        employee[1105] = format_address_code(employee[1105], 'regions_codes', nil)
        employee[1106] = format_address_code(employee[1106], 'comunas_codes', nil)
        employee[1143] = format_code(employee[1143], 'isapre_codes')
        employee[1110] = format_code(employee[1110], 'ccaf_codes')
        employee[1152] = format_code(employee[1152], 'mutual_codes') || 0
        employee
      end

      def add_calculated_fields(employee)
        codes = Lre::HEADER_CODES.keys
        employee = employee.transform_keys(&:to_i)
        library_response = JSON.parse(employee[-9999])
        salary_params = library_response['params']
        hash = {}

        # protection law discounts
        if employee[-1000]
          params = {
            'employee_protection_law'      => employee[-1000],
            'protection_law_code'          => SalaryPayment.protection_law_codes.key(employee[-1001]),
            'suspension_or_reduction_days' => employee[-1002],
            'reduction_percentage'         => employee[-1003],
            'worked_days'                  => employee[-1004],
            'daily_wage'                   => salary_params['daily_wage']
          }
          result = { 'sueldo_base' => employee[-1006] }
          previred = nil
          suspension = CalculateSalary.get_suspencion(params, result, previred)
          employee[2101] = employee[2101] - suspension
        end

        # data from salary 'screenshot'
        employee[1115] = if salary_params['daily_wage']
                           employee[-9001]
                         elsif salary_params['salary_start_date'].to_date.month == @month && salary_params['salary_start_date'].to_date.year == @year
                           employee[-9002] - salary_params['salary_start_date'].to_date.day + 1
                         else
                           employee[-9002]
                         end
        employee[3141] = if salary_params['subsidy_young_worker'] && salary_params['has_ips']
                           employee[-9011] + employee[-9013]
                         elsif salary_params['subsidy_young_worker']
                           employee[-9011] + employee[-9012]
                         elsif salary_params['has_ips']
                           employee[-9013]
                         else
                           employee[-9012]
                         end
        employee[3183] = salary_params['afp_second_account'] +
                         salary_params['descuento_dental_ccaf'] +
                         salary_params['descuento_leasing_ccaf'] +
                         salary_params['descuento_seguro_de_vida_ccaf'] +
                         salary_params['otros_descuentos_ccaf'] +
                         salary_params['descuento_cargas_familiares_ccaf']

        hash[5210] = 0
        codes.select { |c| c > 2099 && c < 2200 }.each do |n|
          hash[5210] += employee[n].to_i
        end
        hash[5220] = employee[2201].to_i + employee[2202].to_i + employee[2203].to_i + employee[2204].to_i
        hash[5230] = 0
        codes.select { |c| c > 2299 && c < 2400 }.each do |n|
          hash[5230] += employee[n].to_i
        end
        hash[5240] = employee[2417].to_i + employee[2418].to_i
        hash[5301] = 0
        codes.select { |c| c > 3099 && c < 3200 }.each do |n|
          hash[5301] += employee[n].to_i
        end
        hash[5361] = employee[3161].to_i + employee[3165].to_i
        hash[5341] = employee[3141].to_i + employee[3143].to_i + employee[3144].to_i + employee[3145].to_i + employee[3146].to_i +
                     employee[3151].to_i + employee[3154].to_i + employee[3155].to_i + employee[3156].to_i + employee[3157].to_i +
                     employee[5358].to_i
        hash[5302] = hash[5301].to_i - (hash[5361].to_i + employee[5362].to_i + hash[5341].to_i)
        hash[5410] = 0
        codes.select { |c| c > 4099 && c < 4200 }.each do |n|
          hash[5410] += employee[n].to_i
        end
        hash[5502] = employee[2313].to_i + employee[2314].to_i + employee[2315].to_i + employee[2316].to_i + employee[2331].to_i +
                     employee[2417].to_i + employee[2418].to_i
        hash[5564] = employee[2417].to_i + employee[2418].to_i
        hash[5565] = employee[2313].to_i + employee[2314].to_i + employee[2315].to_i + employee[2316].to_i + employee[2331].to_i
        hash[5201] = hash[5210].to_i + hash[5220].to_i + hash[5230].to_i + hash[5240].to_i
        hash[5501] = hash[5201].to_i - hash[5301].to_i
        hash[1115] = employee[1115]
        hash[1117] = employee[1117]
        hash[2101] = employee[2101]
        hash[2102] = employee[2102]
        hash[2103] = employee[2103]
        hash[2110] = employee[2110]
        hash[2311] = employee[2311]
        hash[2347] = employee[2347]
        hash[3141] = employee[3141]
        hash[3147] = employee[3147]
        hash[3183] = employee[3183]

        hash
      end

      def validate_data
        errors = []
        @employees.each do |employee|
          Lre.mandatory_fields.each do |field|
            next if employee[field[0]].present?

            errors << { employee_fullname: employee[1001],
                        message: I18n.t('views.remunerations.lre.presence_field_error_message', field: field[1]),
                        employee_id: employee[1000] }
          end
        end
        errors
      end

      def format_code(employee_code, code_to_format)
        path = File.expand_path("#{Rails.root}/app/lib/db/lre")
        YAML.load_file(File.join(path, "#{code_to_format}.yaml"))[code_to_format][employee_code]
      end

      def format_address_code(value, address_kind, default_value)
        return if value.nil?

        path = File.expand_path("#{Rails.root}/app/lib/db/lre")
        options = YAML.load_file(File.join(path, "#{address_kind}.yaml"))[address_kind]
        chosen_option = FuzzyMatch.new(options.map { |option| option['name'] }).find(value) || default_value
        return if chosen_option.nil?

        options.find { |option| option['name'] == chosen_option }['code']
      end

      def self.group_errors_by_employee(errors)
        errors.group_by { |error| error[:employee_id] }.values
          .map do |employee_array|
            { fullname: employee_array.first[:employee_fullname],
              messages: employee_array.map { |error| error[:message] } }
          end
      end

      def self.create_file(data, name, user, community)
        f = File.new(name, 'w+')
        if !user.admin && (user.demo || community.demo)
          f.puts 'Este archivo no se encuentra disponible para la comunidad demo.'
        else
          data.each { |row| f.puts row }
        end
        f
      end
    end
  end
end
