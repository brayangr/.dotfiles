FactoryBot.define do
  factory :license_draft do
    association :salary_payment_draft
    days { Faker::Number.number(digits: 1) }

    extra_hour { 1 }
    extra_hour_2 { 1 }
    extra_hour_3 { 1 }
    worked_days { 1 }
    bono_days { 1 }
  end
end
