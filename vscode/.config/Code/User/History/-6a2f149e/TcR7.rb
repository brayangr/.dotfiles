require 'rails_helper'

RSpec.describe DataImportJob, type: :job do
  include ActionDispatch::TestProcess::FixtureFile
  include StubRequestsHelper

  let(:user)      { create(:user, :admin) }
  let(:community) { create(:community) }
  let(:job_params) do
    {
      excel_upload_id: excel_upload.id,
      _community_id: community.id,
      locale: I18n.locale.to_s
    }
  end

  describe 'Service Billing import' do
    let(:excel_upload) do
      ExcelUpload.create(
        name: 'Egresos',
        excel: fixture_file_upload('service_billing_upload_test.xlsx'),
        uploaded_by: user.id,
        community_id: community.id
      )
    end

    let(:service_billing_attributes) do
      {
        name: 'Mi egreso de prueba',
        community_id: community.id,
        price: 0.4545e4
      }
    end

    before do
      stub_request_data_import_excel(
        body: file_fixture('service_billing_upload_test.xlsx')
      )
    end

    def service_billing_community_transaction_quantity
      CommunityTransaction.where(origin_class: 'ServiceBilling', origin_id: ServiceBilling.last&.id).count
    end

    it 'Should generate a new record' do
      expect { described_class.perform_now(**job_params) }.to change { ServiceBilling.count }.by(1)
    end

    it 'Should assign the attributes correctly' do
      described_class.perform_now(**job_params)

      last_service_billing = ServiceBilling.last

      expect(last_service_billing).to have_attributes(service_billing_attributes)
      expect(last_service_billing.category.name).to eql('Categoria test')
      expect(last_service_billing.category.sub_name).to eql('Subcategoria test')
    end

    it 'Should generate the community transaction' do
      expect { described_class.perform_now(**job_params) }.to change { service_billing_community_transaction_quantity }.by(1)
    end
  end

  describe 'Property import' do
    describe 'Recalculate common expenses logic' do
      let(:excel_upload) do
        ExcelUpload.create(
          name: 'Copropietarios',
          excel: fixture_file_upload('properties_upload_test.xlsx'),
          uploaded_by: user.id,
          community_id: community.id
        )
      end

      before do
        stub_request_data_import_excel(
          body: file_fixture('properties_upload_test.xlsx')
        )
      end

      # This job will be enqueued 0 times once the after_commit in Setting is deleted
      xit 'should enqueue recalculate job 0 times if all properties are new' do
        expect {
          described_class.perform_now(**job_params)
        }.to have_enqueued_job(GeneratePeriodExpenseJob).exactly(5).times
      end

      it 'should enqueue recalculate job 1 time if community already had properties' do
        create(:property, community: community)

        expect {
          described_class.perform_now(**job_params)
        }.to have_enqueued_job(GeneratePeriodExpenseJob).exactly(1).times
      end
    end

    describe 'Size update' do
      let!(:property) { create(:property, community: community, name: 'property_test', size: 0.5) }
      let(:excel_upload) do
        ExcelUpload.create(
          name: 'Copropietarios',
          excel: fixture_file_upload('properties_upload_test_case_2.xlsx'),
          uploaded_by: user.id,
          community_id: community.id,
          admin: true
        )
      end

      before do
        stub_request_data_import_excel(
          body: file_fixture('properties_upload_test_case_2.xlsx')
        )
      end

      context 'with open transfer in period' do
        it 'should not update size' do
          transfer = create(:transfer, transfer_date: Time.now, period_expense: community.get_open_period_expense)
          create(:property_transfer, active: true, property_id: property.id, transfer: transfer)
          expect {
            described_class.perform_now(**job_params)
          }.to_not change { property.reload.size }
        end
      end

      context 'without open transfer in period' do
        it 'should update size' do
          expect {
            described_class.perform_now(**job_params)
          }.to change { property.reload.size }.from(0.5).to(0.03)
        end
      end

    end
  end

  describe 'Subproperty import' do
    let!(:aliquot) do
      aliquot = create(:aliquot, community: community, name: 'AliquotTest')
      property_aliquot = create(:property_aliquot, :for_property, aliquot: aliquot)
      property_aliquot.property_unit.update(name: 'PropertyTest', community_id: community.id)
      aliquot
    end

    let(:excel_upload) do
      ExcelUpload.create(
        name: 'SubPropiedades',
        excel: fixture_file_upload('subproperties_upload_test.xlsx'),
        uploaded_by: user.id,
        community_id: community.id
      )
    end

    before do
      stub_request_data_import_excel(
        body: file_fixture('subproperties_upload_test.xlsx')
      )
    end

    it 'should create records' do
      expect { described_class.perform_now(**job_params) }.to change { PropertyAliquot.count }.by(3)
    end

    it 'should not update aliquot size' do
      expect { described_class.perform_now(**job_params) }.not_to change { aliquot.total_area }
    end
  end

  describe 'Payments import' do
    let(:excel_upload) do
      ExcelUpload.create(
        name: 'Recaudacion',
        uploaded_by: user.id,
        community_id: community.id,
        excel: fixture_file_upload('recaudacion_payments_upload.xlsx')
      )
    end

    context 'Property user with valid email' do
      before do
        create(:property, :with_active_property_user_and_user, name: 'Torre', community: community)
      end

      it 'should create records' do
        stub_request_data_import_excel(
          body: file_fixture('recaudacion_payments_upload.xlsx')
        )

        expect { described_class.perform_now(**job_params) }.to change { Payment.count }.by(3)
      end

      it 'should not create records when create_at is invalid' do
        excel_upload.update(excel: fixture_file_upload('recaudacion_payments_with_errors_upload.xlsx'))

        stub_request_data_import_excel(
          body: file_fixture('recaudacion_payments_with_errors_upload.xlsx')
        )

        expect { described_class.perform_now(**job_params) }.to change { Payment.count }.by(0)
      end

      it 'should enqueued the GeneratePaymentPdfJob' do
        stub_request_data_import_excel(
          body: file_fixture('recaudacion_payments_upload.xlsx')
        )

        expect { described_class.perform_now(**job_params) }.to have_enqueued_job(GeneratePaymentPdfJob).exactly(3).times
      end

      it 'should enqueued the TryNotifyPaymentReceiptJob' do
        stub_request_data_import_excel(
          body: file_fixture('recaudacion_payments_upload.xlsx')
        )

        described_class.perform_now(**job_params)

        job_enqueued = enqueued_jobs.detect { |job| job['job_class'] == 'TryNotifyPaymentReceiptJob' }

        expect(job_enqueued.present?).to be_truthy
      end
    end

    context 'Property user with not valid email' do
      before do
        create(:property, :no_users_with_valid_email, name: 'Torre', community: community)
      end

      it 'should enqueued the GeneratePaymentPdfJob' do
        stub_request_data_import_excel(
          body: file_fixture('recaudacion_payments_upload.xlsx')
        )

        expect { described_class.perform_now(**job_params) }.to have_enqueued_job(GeneratePaymentPdfJob).exactly(3).times
      end

      it 'should not enqueued the TryNotifyPaymentReceiptJob' do
        stub_request_data_import_excel(
          body: file_fixture('recaudacion_payments_upload.xlsx')
        )

        described_class.perform_now(**job_params)

        job_enqueued = enqueued_jobs.detect { |job| job['job_class'] == 'TryNotifyPaymentReceiptJob' }

        expect(job_enqueued.present?).to be_falsey
      end
    end
  end
end
