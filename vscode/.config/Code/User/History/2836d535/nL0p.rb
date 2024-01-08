FactoryBot.define do
  factory :community_package do
    association :community, factory: :community
    association :account, factory: :account
    name { 'MyString' }
    price { 1 }
    country_code { 'CL' }
    package_type { 1 }
    currency_type { 'UF' }
    months_to_bill { 1 }
    invoice_type { 1 }
    exempt_percentage { 100.to_f }
    active { true }
    periodicity { '1.month' }
    next_billing_date { 1.month.from_now.to_date }

    factory :cf_community_package do
      package_type { 0 }
    end

    trait :with_invoice_type_calendar do
      invoice_type { 0 }
    end

    trait :with_anually_bill do
      months_to_bill { 12 }
    end

    trait :from_mexico do
      country_code { 'MX' }
    end

    trait :with_half_exempt_percentage do
      exempt_percentage { 50.to_f }
    end

    trait :without_price do
      price { 0 }
    end

    trait :with_past_billing_date do
      next_billing_date { 1.month.ago }
    end

    trait :with_community_with_invoice do
      after(:create) do |com_package|
        com_package.community.period_expenses.last.update(invoiced: true)
        com_package.community.period_expenses.last.update(common_expense_generated: true)
      end
    end

    trait :cf_type do
      package_type { 0 }
    end

    trait :rm_type do
      package_type { 2 }
    end

    trait :lc_type do
      package_type { 3 }
    end

    trait :cb_package_type do
      package_type { 4 }
    end

    trait :inactive do
      active { false }
    end

    trait :with_past_billing_date do
      next_billing_date { 1.month.ago.to_date }
    end

    factory :community_package_calendar, traits: [:with_invoice_type_calendar]
    factory :community_package_mx_and_calendar, traits: [:from_mexico, :with_invoice_type_calendar]
  end
end
