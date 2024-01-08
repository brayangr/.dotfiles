require 'rails_helper'

RSpec.describe Admin::PaymentsStpDispertionsSupportsController, type: :controller do
  let(:user) { create(:user_superadmin) }
  before { login(user) }

  describe 'GET /admin/payments_stp_dispertions_supports' do
    it 'should show payments stp dispertions support section' do
      community_one = create(:community, :with_stp_company)
      setting_one = community_one.settings.create(code: 'stp_payment_method', value: 1)
      setting_one.update(value: 1)
      community_one.banking_setting.update(costs_center_name: "test-costs-center")
      create(:mexican_community, :no_period_control, :with_mx_company, :with_stp_company)
      create_list(:dispersed_payment, 5)
      params = {community_id: community_one.id}
      get :index, params: params
      tab = @controller.instance_variable_get(:@tab)
      dispertion_payments = @controller.instance_variable_get(:@dispertion_payments)
      expect(tab).to eql('payments_stp_supports')
      expect(dispertion_payments.count).to eql(5)
    end
    it 'should show payments stp dispertions support section filter by transaction id' do
      community_one = create(:community, :with_stp_company)
      setting_one = community_one.settings.create(code: 'stp_payment_method', value: 1)
      setting_one.update(value: 1)
      community_one.banking_setting.update(costs_center_name: "test-costs-center")
      create(:mexican_community, :no_period_control, :with_mx_company, :with_stp_company)
      dispersed_payments = create_list(:dispersed_payment, 5)
      params = {community_id: community_one.id, search_query: dispersed_payments.first.transaction_id}
      get :index, params: params
      tab = @controller.instance_variable_get(:@tab)
      dispertion_payments = @controller.instance_variable_get(:@dispertion_payments)
      expect(tab).to eql('payments_stp_supports')
      expect(dispertion_payments.count).to eql(1)
    end
    it 'should show payments stp dispertions support section filter by transaction code' do
      community_one = create(:community, :with_stp_company, country_code: 'MX')
      setting_one = community_one.settings.create(code: 'stp_payment_method', value: 1)
      setting_one.update(value: 1)
      community_one.banking_setting.update(costs_center_name: "test-costs-center")
      create(:mexican_community, :no_period_control, :with_mx_company, :with_stp_company, country_code: 'MX')
      dispersed_payments = create_list(:dispersed_payment, 5)
      params = {community_id: community_one.id, search_query: dispersed_payments.first.transaction_code}
      get :index, params: params
      tab = @controller.instance_variable_get(:@tab)
      dispertion_payments = @controller.instance_variable_get(:@dispertion_payments)
      expect(tab).to eql('payments_stp_supports')
      expect(dispertion_payments.count).to eql(1)
    end
  end
end
