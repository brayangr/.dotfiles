require 'rails_helper'

RSpec.describe ReportQueries, type: :module do
  let(:community) { create(:community, :with_initial_period) }

  describe '#get_outcomes' do
    context 'when nullify service_billing' do
      let!(:service_billing) { create(:service_billing, community: community, period_expense: community.get_open_period_expense, paid_at: Date.today, paid: true) }
      let(:user) { create(:user) }

      it 'should bring no row' do
        service_billing.nullify(user)
        when_nullified = described_class.get_outcomes(community_id: community.id)
        expect(when_nullified.to_a.size).to eq(0)
      end

      context 'when denullify service_billing' do
        # This test will be commented until be solved in SAAS-1718
        xit 'should bring 1 row' do
          service_billing.nullify(user)
          service_billing.denullify(true)
          when_denullified = described_class.get_outcomes(community_id: community.id)
          expect(when_denullified.to_a.size).to eq(1)
          expect(service_billing.price == when_denullified.first['total_amount']).to be_truthy
        end
      end
    end
  end
end
