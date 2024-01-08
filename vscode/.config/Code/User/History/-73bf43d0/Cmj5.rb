FactoryBot.define do
  factory :salary do
    association :employee

    community { employee.community }
    account_rut { Faker::ChileRut.full_rut(min_rut: 1_000_000) }
    active { true }
    afp { Salary::AFP.sample }
    age { 'MyString' }
    base_price { Faker::Number.between(from: 300_000, to: 2_000_000) }
    contract_type { 'Indefinido' }
    employee_type { 'Dependiente' }
    institucion_apvi2 { Constants::SalaryPayments::NO_VOLUNTARY_SAVINGS }
    isapre { 'MyString' }
    lunch_benefit { 1 }
    number_of_loads { 1 }
    plan_isapre { 1 }
    start_date { Time.now.beginning_of_year }
    transportation_benefit { 1 }
    vacations_start_date { start_date + 5.days }
    week_hours { 1 }

    trait :for_previred do
      employee_type { 'Dependiente' }
      contract_type { 'Indefinido' }
      has_isapre { true }
      isapre { (Constants::Isapre::ISAPRE.keys - ['Esencial', 'Sin Isapre', 'Fonasa']).sample }
    end

    before(:create) do |salary|
      salary.employee = create(:employee, community: salary.community)
    end
  end

  factory :active_salary, parent: :salary do |f|
    f.active { true }
  end

  factory :full_time_salary, parent: :salary do
    fake_start_date = Time.now.at_beginning_of_day - 2.years - 1.day
    active { true }
    daily_wage { false }
    week_hours { 40 }
    start_date { fake_start_date }
    vacations_start_date { fake_start_date }
  end

  # Part time
  # Working 3 times a week, contract started 2 years ago
  factory :part_time_salary_3_days_a_week, parent: :salary do
    fake_start_date = Time.now.at_beginning_of_day - 2.years - 1.day
    active { true }
    daily_wage { true }
    days_per_week { 3 }
    week_hours { 24 }
    start_date { fake_start_date }
    vacations_start_date { fake_start_date }
  end
end
