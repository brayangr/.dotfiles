FactoryBot.define do
  factory :salary_payment_draft do
    association :salary
    association :payment_period_expense, factory: %i[period_expense this_month]
    association :creator, factory: :user

    extra_hour { rand(1..10) }
    extra_hour_2 { 1 }
    extra_hour_3 { 1 }
    worked_days { 1 }
    bono_days { 1 }
  end
end
