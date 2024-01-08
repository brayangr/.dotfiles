FactoryBot.define do
  factory :salary_payment_draft do
    association :salary
    association :payment_period_expense, factory: %i[period_expense this_month]
    association :creator, factory: :user

    extra_hour { 1 }
    extra_hour_2 { 1 }
    extra_hour_3 { 1 }
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
  end
end
