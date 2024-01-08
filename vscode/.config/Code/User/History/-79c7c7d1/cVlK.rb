FactoryBot.define do
  factory :dispersed_payment do
    payment_id { payment }
    transaction_id { Faker::Number.number(digits: 8) }
    dispersion_date { Time.now }
    description { 'TEST STP Dispertion' }
    intend { 1 }
    status { 3 }

    transient do
      test_costs_center { nil }
    end

    metadata { {message: { 'orden_pago': { 'clave_rastreo': "CFTEST#{Faker::Name.name}",
                                           'empresa': test_costs_center.present? ? test_costs_center : 'test-costs-center',
                                           'cuenta_ordenante': '646180203900010006'}}}}

  end
end
