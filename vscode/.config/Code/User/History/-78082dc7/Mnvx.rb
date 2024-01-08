FactoryBot.define do
  factory :discounts_draft do
    association :salary_payment_draft
    days { Faker::Number.number(digits: 1) }
    start_date { Time.now.to_date }
    end_date { Time.now.to_date + 5.days }
    reason { DiscountsDraft.reasons.except('custom_discount').keys.sample }
  end

  factory :another_discounts_draft do
    association :salary_payment_draft
    start_date { Time.now.to_date }
    end_date { Time.now.to_date + 5.days }
    reason { DiscountsDraft.reasons[:custom_discount] }
  end
end
