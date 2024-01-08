FactoryBot.define do
  factory :salary_additional_info do
    name { Faker::String.random(length: 4) }
    value { Faker::Number.between(from: 1, to: 20) }

    trait :bonus do
    end
  end
end
