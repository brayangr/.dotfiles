require 'rails_helper'
require 'support/shared_examples/standard_service_object_examples'
require 'support/shared_examples/standard_service_object_subclass_examples'

RSpec.describe Remuneration::SalaryPaymentDrafts::ResetResponse do
  include StandardServiceObjectsHelper

  it_behaves_like :standard_service_object
  it_behaves_like :standard_service_object_subclass

  let(:community) { create(:community) }
  let(:controller_context) { Remuneration::SalaryPaymentDraftsController.new }
  let(:salary_payment_draft) { create(:salary_payment_draft) }

  describe 'Should instantiate expected variables in controller' do
    let(:params) { { salary_payment_draft_id: salary_payment_draft.id } }

    it 'Should set worked_days and bono_days to 0' do
      expect {
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      }.to change { salary_payment_draft.reload.worked_days }
    end
  end
end
