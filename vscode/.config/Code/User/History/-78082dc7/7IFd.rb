FactoryBot.define do
  factory :license_draft do
    association :salary_payment_draft
    days { Faker::Number.number(digits: 1) }
    start_date { Time.now.to_date }
    end_date { Time.now.to_date + 5.days }
    ultimo_total_imponible_sin_licencia { Faker::Number.number(digits: 5) }
  end
end
