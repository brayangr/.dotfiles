FactoryBot.define do
  factory :salary_payment do
    association :salary
    association :period_expense
    association :payment_period_expense, factory: %i[period_expense this_month]

    employee { salary.employee }
    extra_hour { 1 }
    discount_days { 0 }
    advance { 1 }
    advance_gratifications { 1 }
    apv { 1 }
    special_bonus { 1 }
    refund { 1 }
    viaticum { 1 }
    lost_cash_allocation { 1 }
    allocation_tool_wear { 1 }
    union_fee { 1 }
    legal_holds { 1 }
    nullified_at { nil }
    cotizacion_empleador_apvc { Faker::Number.between(from: 10, to: 20) }
    cotizacion_trabajador_apvc { Faker::Number.between(from: 10, to: 20) }

    trait :not_nullified do
      nullified { false }
    end

    trait :with_apv do
      tipo_apv { 0 }
      apv { Faker::Number.number(digits: 5) }
      result_apv { apv }
    end

    trait :for_previred do
      after(:create) do |salary_payment|
        Remuneration::SalaryPayments::PreCalculateSalary.call(salary_payment: salary_payment)
      end
    end

    trait :calculated do
      after(:create) do |salary_payment|
        Remuneration::SalaryPayments::CalculateSalary.call(salary_payment: salary_payment)
      end
    end

    trait :full do
      before(:create) do |salary_payment|
        salary_payment.salary = create(:salary, :for_previred, active: true)
        community = create(:community, :with_initial_period, :with_address)
        salary_payment.employee = create(:employee, community: community)
      end

      after(:create) do |salary_payment|
        Remuneration::SalaryPayments::CalculateSalary.call(salary_payment: salary_payment)
      end
    end

    trait :with_medical_license do
      before(:create) do |salary_payment|
        community = create(:community, :with_initial_period, :with_mutual, :with_address)
        salary_payment.salary = create(:salary, :for_previred, active: true, community: community)
        salary_payment.community = community
        salary_payment.dias_licencia = Faker::Number.within(range: 1..30)
      end
    end

    trait :with_medical_license_and_without_mutual do
      before(:create) do |salary_payment|
        community = create(:community, :with_initial_period, mutual: nil)
        salary_payment.salary = create(:salary, :for_previred, active: true, community: community)
        salary_payment.community = community
        salary_payment.dias_licencia = Faker::Number.within(range: 1..30)
      end
    end

    trait :with_spouse_data do
      before(:create) do |salary_payment|
        salary_payment.spouse = true
        salary_payment.spouse_voluntary_amount = Faker::Number.between(from: 10, to: 20)
        salary_payment.spouse_periods_number = Faker::Number.between(from: 10, to: 20)
        salary_payment.spouse_capitalizacion_voluntaria = Faker::Number.between(from: 10, to: 20)
      end
    end

    trait :with_employee_protection_law do
      before(:create) do |salary_payment|
        salary_payment.employee_protection_law = true
        salary_payment.protection_law_code = SalaryPayment.protection_law_codes.keys.sample
        salary_payment.suspension_or_reduction_days = Faker::Number.between(from: 1, to: 20)

        if salary_payment.protection_law_code == SalaryPayment.protection_law_codes.invert[2]
          salary_payment.reduction_percentage = Faker::Number.between(from: 1, to: 49)
        else
          salary_payment.afc_informed_rent = Faker::Number.between(from: 100, to: 1000)
        end
      end
    end

    trait :with_adjust_by_rounding do
      before(:create) do |salary_payment|
        salary_payment.adjust_by_rounding = true
      end
    end
  end

  factory :salary_payment_with_employee_protection_law, parent: :salary_payment do
    employee_protection_law { true }
    suspension_or_reduction_days { Faker::Number.between(from: 1, to: 30) }
    reduction_percentage { Faker::Number.between(from: 0.1, to: 99.9) }
  end

  factory :salary_with_initial_setup_periods, parent: :salary_payment do
    before(:create) do |salary_payment|
      create(:period_expense, community: salary_payment.employee.community, initial_setup: true, period: 2.years.ago)
    end
  end
end
