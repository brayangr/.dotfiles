require 'rails_helper'

RSpec.describe PeriodControl, type: :module do
  include ActiveSupport::Testing::TimeHelpers
  include AssetStub

  before do
    stub_highcharts
  end

  let(:user) { create(:user, :admin) }
  let(:community) { create(:community) }
  let(:property) { create(:property, community: community) }
  let(:property_fine) { create(:property_fine, community: community, property: property) }
  before do
    allow(Aws::DynamoDbClient).to receive_message_chain('new.safe_create_item') { true }
  end

  describe 'pre close method' do
    before do
      property_fine.period_expense.update(community: community)
    end
    context 'property fine model' do
      it 'when proration is negative return false' do
        property_fine.property.update_column(:size, -1)
        property_fine.period_expense.pre_close
        property_fine_period_expense = property_fine.period_expense
        expect(property_fine_period_expense.common_expense_generated).to be_falsey
        expect(property_fine_period_expense.blocked).to be_falsey
      end

      it 'when update provision settings' do
        period_expense_community = property_fine.period_expense.community
        period_expense_community.get_setting_value('enabled_provisions')
        period_expense_community.settings.where(code: 'enabled_provisions').first.update_column(:value, 1)
        period_expense_community.settings.reload
        property_fine.period_expense.pre_close
        expect(period_expense_community.get_setting('enabled_provisions').value).to be_zero
      end

      it 'when common_expense_generated return false' do
        property_fine.period_expense.update_column(:common_expense_generated, true)
        property_fine.period_expense.pre_close
        expect(property_fine.period_expense.blocked).to be_falsey
      end

      it 'when property fine invalid' do
        property_fine.period_expense.pre_close
        property_fine.price = property_fine.price + Faker::Number.decimal
        expect(property_fine.valid?).to be_falsey
      end

      context 'when assign values successfully' do
        before do
          property_fine.period_expense.pre_close
        end

        it 'when common expense generated to be_truthy' do
          expect(property_fine.period_expense.common_expense_generated).to be_truthy
        end

        it 'when period expense blocket be truthy' do
          expect(property_fine.period_expense.blocked).to be_truthy
        end

        it 'when common expense generated at to be present' do
          expect(property_fine.period_expense.common_expense_generated_at).to be_present
        end

        it 'when persisted period expense' do
          expect(property_fine.period_expense.persisted?).to be_truthy
        end

        it 'when enqueue close period expense job' do
          job_expense_id = enqueued_jobs.detect { |job| job['job_class'] == ClosePeriodExpenseJob.to_s }['arguments'].first['period_expense_id']
          expect(job_expense_id).to eq property_fine.period_expense.id
        end
      end
    end
  end

  describe 'notify close method' do
    let(:payment) { create(:payment, community: community, confirmed: true, property: property, period_expense: property_fine.period_expense) }
    let(:bundle_payment) { create(:bundle_payment, user: user, period_expense: property_fine.period_expense) }
    let(:currency) { create(:currency, name: 'Pesos') }
    let(:community_interest) { create(:community_interest, currency: currency, community: property_fine.community, fixed: true, amount: 1, rate_type: 1) }
    let(:common_expense) do
      create(:common_expense,
             price: 10_000,
             property: property,
             community: property_fine.community,
             period_expense: property_fine.period_expense, to_delete: false)
    end
    let!(:debt_one) do
      create(:debt, :unpaid,
             common: true,
             property: property,
             common_expense: common_expense,
             last_interest_bill_date: property_fine.period_expense.close_interest_date + 1.day,
             priority_date: property_fine.period_expense.expiration_date)
    end
    let!(:interest) do
      create(:interest,
             description: 'interest',
             origin_debt: debt_one,
             base_price: debt_one.price,
             period_expense: property_fine.period_expense,
             community_interest: community_interest,
             price: 100,
             property: property)
    end

    context 'when assigns attributes' do
      before do
        property_fine.period_expense.notify_close
      end

      it 'when issued to be falsey' do
        expect(payment.issued).to be_falsey
      end

      it 'when bundle payment issued to be falsey' do
        expect(bundle_payment.issued).to be_falsey
      end

      it 'when property fine issued to be falsey' do
        expect(property_fine.issued).to be_falsey
      end

      it 'when business transaction to be present' do
        expect(BusinessTransaction.find_by(origin_id: interest)).to be_present
      end

      it 'when initial setup to be falsey' do
        expect(common_expense.initial_setup).to be_falsey
      end

      it 'when notify close 2 job enqueue' do
        job_expense_id = enqueued_jobs.detect { |job| job['job_class'] == NotifyClose2Job.to_s }['arguments'].first['period_expense_id']
        expect(job_expense_id).to eq property_fine.period_expense.id
      end
    end

    it 'when exists initial setup' do
      property_fine.period_expense.update(initial_setup: true)
      property_fine.period_expense.notify_close
      common_expense.reload
      expect(common_expense.initial_setup).to be_truthy
      job_expense_id = enqueued_jobs.detect { |job| job['job_class'] == NotifyClose2Job.to_s }['arguments'].first['period_expense_id']
      expect(job_expense_id).to eq property_fine.period_expense.id
    end
  end

  describe 'notify close 2 method' do
    let!(:common_expense) do
      create(:common_expense,
             price: 10_000,
             property: property,
             community: property_fine.period_expense.community,
             period_expense: property_fine.period_expense, to_delete: false)
    end

    context 'when notify close 2 scenarios' do
      before do
        property_fine.period_expense.notify_close_2(delay: true, notify: true, user: user, new_bt_date: Time.now)
      end

      it 'when verify all common expense, assigns values' do
        property_fine.period_expense.community.settings.where(code: 'period_control').first.update_column(:value, 1)
        property_fine.period_expense.community.settings.reload
        expect(property_fine.period_expense.common_expenses.first.verified).to be_truthy
      end

      it 'when bill create successfully' do
        expect(property_fine.period_expense.bills).to be_present
      end

      it 'when business transaction create successfully' do
        expect(BusinessTransaction.find_by(origin_id: common_expense.id)).to be_present
      end

      it 'when bill details create successfully' do
        expect(property_fine.period_expense.bills.first.bill_details).to be_present
      end

      it 'when common expense have property transaction' do
        common_expense.reload
        expect(common_expense.property_transaction_id).to eq common_expense.property_transaction.id
      end

      it 'when common expense have bill' do
        common_expense.reload
        expect(common_expense.bill_id).to eq property_fine.period_expense.bills.first.id
      end

      it 'when enqueue notify close 3 job' do
        job_expense_id = enqueued_jobs.detect { |job| job['job_class'] == NotifyClose3Job.to_s }['arguments'].first['period_expense_id']
        expect(job_expense_id).to eq property_fine.period_expense.id
      end
    end

    it 'when skip verify all common expense assginations' do
      property_fine.period_expense.update(initial_setup: true)
      expect { property_fine.period_expense.notify_close_2(delay: true, notify: true, user: user, new_bt_date: Time.now) }.to have_enqueued_job(NotifyClose3Job)
    end

    it 'when delay false, notify_close_3' do
      property_fine.period_expense.update(initial_setup: true)
      property_fine.period_expense.notify_close_2(delay: false, notify: true, user: user, new_bt_date: Time.now)
      expect(PeriodExpenseRegister.find_by(period_expense_id: property_fine.period_expense)).to be_present
    end
  end

  describe 'notify close 3 method' do
    let!(:future_payment) { create(:payment, community: community, property: property, period_expense: community.get_open_period_expense.get_next.first, confirmed: true) }
    let!(:current_period_bill) { create(:bill, property: property, period_expense: community.get_open_period_expense, price: 5_000) }
    let(:employee) { create(:employee, :with_active_salary, community: community) }
    let!(:advance) { create(:advance, period_expense: community.get_open_period_expense, employee: employee, community: community, recurrent: true) }

    context 'when notify close 3 scenarios' do
      before do
        community.get_setting_value('ass_enabled')
        community.settings.where(code: 'ass_enabled').first.update_column(:value, 1)
        community.settings.reload
        community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now)
      end

      it 'should assign future payments to current period bills' do
        future_payment.reload
        expect(future_payment.bill_id).to eq current_period_bill.id
      end

      it 'should update global_amount with all bills sum' do
        expect(community.get_open_period_expense.global_amount).to eq community.get_open_period_expense.bills.sum(:price)
      end

      context 'when the community have remuneration package' do
        before { create(:community_package, :rm_type, community: community) }

        context 'when delay is true'
        it 'should enqueue GenerateRecurrentAdvancesJob' do
          expect { community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now) }.to have_enqueued_job(GenerateRecurrentAdvancesJob)
        end
      end

      context 'when the community does not have remuneration package' do
        it 'should not enqueue GenerateRecurrentAdvancesJob' do
          expect { community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now) }.to_not have_enqueued_job(GenerateRecurrentAdvancesJob)
        end
      end

      it 'should enqueue BuildAccountSummarySheetsJob' do
        expect { community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now) }.to have_enqueued_job(BuildAccountSummarySheetsJob)
      end

      it 'should enqueue AssignBundlePaymentToAccountSummarySheetsJob' do
        expect { community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now) }.to have_enqueued_job(AssignBundlePaymentToAccountSummarySheetsJob)
      end

      it 'should enqueue GeneratePeriodExpenseJob' do
        expect { community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now) }.to have_enqueued_job(GeneratePeriodExpenseJob)
      end

      it 'should assign bill_generated and bill_generated_at when closing period is initial setup' do
        freeze_time
        pe = community.get_open_period_expense
        pe.update(bill_generated: false, bill_generated_at: nil, initial_setup: true)
        pe.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now)
        expect(pe.bill_generated && (pe.bill_generated_at == Time.now)).to be_truthy
      end
    end

    context 'when ass setting is disabled' do
      let(:request) { community.get_open_period_expense.notify_close_3(delay: true, notify: true, current_user: user, new_bt_date: Time.now) }
      before do
        community.get_setting_value('ass_enabled')
        community.settings.where(code: 'ass_enabled').first.update_column(:value, 0)
        community.settings.reload
      end

      it 'should not generate grouped bills' do
        expect { request }.not_to have_enqueued_job(BuildAccountSummarySheetsJob)
        expect { request }.not_to have_enqueued_job(AssignBundlePaymentToAccountSummarySheetsJob)
      end
    end
  end

  describe '#bill_pdf_generation' do
    context 'when there is an error in bills generation' do
      let(:closing_period_expense) { create(:period_expense) }
      let(:bill) { create(:bill, period_expense: closing_period_expense, community: closing_period_expense.community) }

      it 'should call generate_pdf method twice per bill' do
        allow(bill).to receive(:generate_pdf).and_raise(StandardError)

        closing_period_expense.bill_pdf_generation([bill])
        expect(bill).to have_received(:generate_pdf).twice
      end
    end
  end
end
