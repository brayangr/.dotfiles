FactoryBot.define do
  factory :discounts_draft do
    association :salary_payment_draft
    days { Faker::Number.number(digits: 1) }
    start_date { Time.now.to_date }
    end_date { Time.now.to_date + 5.days }
    reason { DiscountsDraft.reasons.keys.sample }
  end
end
