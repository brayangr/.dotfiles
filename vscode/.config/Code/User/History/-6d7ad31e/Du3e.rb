FactoryBot.define do
  factory :salary_additional_info do
    name {""}
    value { Faker::Number.between(from: 1, to: 20) }
  end
end
