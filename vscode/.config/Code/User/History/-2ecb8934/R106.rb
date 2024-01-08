require 'rails_helper'
require 'support/shared_examples/standard_service_object_examples'
require 'support/shared_examples/standard_service_object_subclass_examples'

RSpec.describe Remuneration::SalaryPaymentDrafts::ResetResponse do
  include StandardServiceObjectsHelper

  it_behaves_like :standard_service_object
  it_behaves_like :standard_service_object_subclass

  let(:community) { create(:community) }
  let(:controller_context) { Remuneration::SalaryPaymentDraftsController.new }
  let(:salary_payment_draft) do
    create(:salary_payment_draft, worked_days: 10, bono_days: 8, extra_hour: 10,
                                  extra_hour_2: 8, extra_hour_3: 6)
  end
  let(:user) { create(:user) }

  describe 'Worked days' do
    let(:params) { { salary_payment_draft_id: salary_payment_draft.id, tab: :worked_days, user: user } }

    it 'Should set worked_days and bono_days to 0' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { salary_payment_draft.reload.worked_days }.from(10).to(0)
        .and change { salary_payment_draft.reload.bono_days }.from(8).to(0)
    end

    it 'should not change other values' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { salary_payment_draft.reload.extra_hour }

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { salary_payment_draft.reload.extra_hour_2 }

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { salary_payment_draft.reload.extra_hour_3 }
    end

    it 'should set updater' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
    end

    describe 'Should return expected records' do
      it 'Should return employee with ' do
        response = call_service_object(service_object: described_class, params: params)
        salary = salary_payment_draft.salary
        employee = salary.employee

        expect(response.data[:employee].id).to be_eql(employee.id)
        expect(response.data[:salaries]).to include({ employee.id => salary })
        expect(response.data[:salary_payment_drafts]).to include({ salary.id => salary.salary_payment_drafts.last })
      end
    end
  end

  describe 'Extra hours' do
    let(:params) { { salary_payment_draft_id: salary_payment_draft.id, tab: :extra_hours, user: user } }

    it 'Should set extra hours fields to 0' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { salary_payment_draft.reload.worked_days }.from(10).to(0)
        .and change { salary_payment_draft.reload.bono_days }.from(8).to(0)
    end

    it 'should not change other values' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { salary_payment_draft.reload.extra_hour }

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { salary_payment_draft.reload.extra_hour_2 }

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { salary_payment_draft.reload.extra_hour_3 }
    end

    it 'should set updater' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
    end

    describe 'Should return expected records' do
      it 'Should return employee with ' do
        response = call_service_object(service_object: described_class, params: params)
        salary = salary_payment_draft.salary
        employee = salary.employee

        expect(response.data[:employee].id).to be_eql(employee.id)
        expect(response.data[:salaries]).to include({ employee.id => salary })
        expect(response.data[:salary_payment_drafts]).to include({ salary.id => salary.salary_payment_drafts.last })
      end
    end
  end
end
