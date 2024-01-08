require 'rails_helper'
require 'support/shared_examples/standard_service_object_examples'
require 'support/shared_examples/standard_service_object_subclass_examples'

RSpec.describe Remuneration::SalaryPaymentDrafts::BulkResetResponse do
  include StandardServiceObjectsHelper
  include Rails.application.routes.url_helpers

  it_behaves_like :standard_service_object
  it_behaves_like :standard_service_object_subclass

  let(:user) { create(:user) }
  let(:community) { create(:community) }
  let(:controller_context) { Remuneration::SalaryPaymentDraftsController.new }
  let(:actual_period) { community.get_open_period_expense.period }

  let!(:full_time_salary) { create(:salary, community: community, daily_wage: false, start_date: actual_period - 10.month, active: true) }
  let!(:part_time_salary) { create(:salary, community: community, daily_wage: true, start_date: actual_period - 5.month, active: true) }

  let!(:full_time_employee) { full_time_salary.employee }
  let!(:part_time_employee) { part_time_salary.employee }

  let!(:full_time_employee_salary_payment_draft) do
    create(:salary_payment_draft, worked_days: 10, bono_days: 8, extra_hour: 10,
                                  extra_hour_2: 8, extra_hour_3: 6, salary_id: full_time_salary.id,
                                  payment_period_expense_id: community.get_open_period_expense.id)
  end

  let!(:part_time_employee_salary_payment_draft) do
    create(:salary_payment_draft, worked_days: 10, bono_days: 8, extra_hour: 10,
                                  extra_hour_2: 8, extra_hour_3: 6, salary_id: part_time_salary.id,
                                  payment_period_expense_id: community.get_open_period_expense.id)
  end

  describe 'when tab is :worked_days' do
    let(:params) { { community: community, tab: :worked_days, part_time: true, user: user } }

    context 'with part time employees' do
      it 'should reset bono days and worked days' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { part_time_employee_salary_payment_draft.reload.bono_days }.from(8).to(0)
          .and change { part_time_employee_salary_payment_draft.reload.worked_days }.from(10).to(0)
      end

      it 'should not reset other values' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { part_time_employee_salary_payment_draft.reload.extra_hour }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { part_time_employee_salary_payment_draft.reload.extra_hour_2 }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { part_time_employee_salary_payment_draft.reload.extra_hour_3 }
      end

      it 'should set updater' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { part_time_employee_salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
      end
    end

    context 'with full time employees' do
      it 'should not reset any value' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.updater_id }
      end
    end

    it 'Should instantiate mesage' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@message)).to eq(
        { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      )
    end

    it 'Should instantiate redirection_path' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      open_period_expense = community.get_open_period_expense
      month = open_period_expense.month
      year = open_period_expense.year

      expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
        remuneration_salary_payment_drafts_path(month: month, year: year, tab: :worked_days)
      )
    end

    context 'with filters' do
      let(:period_expense) { create(:period_expense, community: community) }
      let!(:another_part_time_employee_salary_payment_draft) do
        create(:salary_payment_draft, worked_days: 10, bono_days: 8, extra_hour: 10,
                                      extra_hour_2: 8, extra_hour_3: 6, salary_id: part_time_salary.id,
                                      payment_period_expense_id: period_expense.id)
      end

      let(:params) { { community: community, tab: :worked_days, part_time: true, user: user, month: period_expense.month, year: period_expense.year } }

      it 'should not reset values from salary payment drafts that does not match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }.from(10)

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }.from(8)
      end

      it 'should reset bono days and worked days from salary payment drafts that match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { another_part_time_employee_salary_payment_draft.reload.bono_days }.from(8).to(0)
          .and change { another_part_time_employee_salary_payment_draft.reload.worked_days }.from(10).to(0)
      end

      it 'Should instantiate redirection_path' do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

        expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
          remuneration_salary_payment_drafts_path(month: period_expense.month, year: period_expense.year, tab: :worked_days)
        )
      end
    end
  end

  describe 'when tab is :extra_hours' do
    let(:params) { { community: community, tab: :extra_hours, user: user } }

    context 'with part time employees' do
      it 'should reset extra hours fields' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { part_time_employee_salary_payment_draft.reload.extra_hour }.from(10).to(0)
          .and change { part_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8).to(0)
          .and change { part_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6).to(0)
      end

      it 'should not reset other values' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { part_time_employee_salary_payment_draft.reload.bono_days }.from(8)

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { part_time_employee_salary_payment_draft.reload.worked_days }.from(10)
      end

      it 'should set updater' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { part_time_employee_salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
      end
    end

    context 'with full time employees' do
      it 'should reset extra hours fields' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { full_time_employee_salary_payment_draft.reload.extra_hour }.from(10).to(0)
          .and change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8).to(0)
          .and change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6).to(0)
      end

      it 'should not reset other values' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }.from(10)

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }.from(8)
      end
    end

    it 'Should instantiate mesage' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@message)).to eq(
        { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      )
    end

    it 'Should instantiate redirection_path' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      open_period_expense = community.get_open_period_expense
      month = open_period_expense.month
      year = open_period_expense.year

      expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
        remuneration_salary_payment_drafts_path(month: month, year: year, tab: :extra_hours)
      )
    end

    context 'with filters' do
      let(:period_expense) { create(:period_expense, community: community) }
      let!(:another_part_time_employee_salary_payment_draft) do
        create(:salary_payment_draft, worked_days: 10, bono_days: 8, extra_hour: 10,
                                      extra_hour_2: 8, extra_hour_3: 6, salary_id: part_time_salary.id,
                                      payment_period_expense_id: period_expense.id)
      end

      let(:params) { { community: community, tab: :extra_hours, part_time: true, user: user, month: period_expense.month, year: period_expense.year } }

      it 'should not reset values from salary payment drafts that does not match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour }.from(10)

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8)

        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6)
      end

      it 'should reset extra hours from salary payment drafts that match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { another_part_time_employee_salary_payment_draft.reload.extra_hour }.from(10).to(0)
          .and change { another_part_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8).to(0)
          .and change { another_part_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6).to(0)
      end

      it 'Should instantiate redirection_path' do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

        expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
          remuneration_salary_payment_drafts_path(month: period_expense.month, year: period_expense.year, tab: :extra_hours)
        )
      end
    end
  end

  describe 'when tab is :licenses' do
    let(:params) { { community: community, tab: :licenses, user: user } }
    let!(:salary_payment_drafts) do
      salary_payment_drafts = SalaryPaymentDraft.where(payment_period_expense_id: community.get_open_period_expense)

      salary_payment_drafts.each do |draft|
        create_list(:license_draft, 2, salary_payment_draft: draft)
      end

      salary_payment_drafts
    end

    it 'should delete all associated licenses' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { LicenseDraft.count }.from(LicenseDraft.count).to(0)
    end

    it 'should not reset other values' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6)
    end

    it 'should set updater' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { full_time_employee_salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
    end

    it 'Should instantiate mesage' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@message)).to eq(
        { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      )
    end

    it 'Should instantiate redirection_path' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      open_period_expense = community.get_open_period_expense
      month = open_period_expense.month
      year = open_period_expense.year

      expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
        remuneration_salary_payment_drafts_path(month: month, year: year, tab: :licenses)
      )
    end

    context 'with filters' do
      let(:period_expense) { create(:period_expense, community: community) }
      let!(:another_part_time_employee_salary_payment_draft) do
        salary_payment_draft = create(
          :salary_payment_draft,
          worked_days: 10,
          bono_days: 8,
          extra_hour: 10,
          extra_hour_2: 8,
          extra_hour_3: 6,
          salary_id: part_time_salary.id,
          payment_period_expense_id: period_expense.id
        )

        create(:license_draft, salary_payment_draft: salary_payment_draft)

        salary_payment_draft
      end

      let(:params) { { community: community, tab: :licenses, part_time: true, user: user, month: period_expense.month, year: period_expense.year } }

      it 'should not delete license drafts that does not match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to_not change { full_time_employee_salary_payment_draft.reload.license_drafts.count }
          .from(full_time_employee_salary_payment_draft.license_drafts.count)
      end

      it 'should reset extra hours from salary payment drafts that match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { another_part_time_employee_salary_payment_draft.reload.license_drafts.count }
          .from(another_part_time_employee_salary_payment_draft.license_drafts.count).to(0)
      end

      it 'Should instantiate redirection_path' do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

        expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
          remuneration_salary_payment_drafts_path(month: period_expense.month, year: period_expense.year, tab: :licenses)
        )
      end
    end
  end

  describe 'when tab is :discounts_days' do
    let(:params) { { community: community, tab: :discounts_days, user: user } }
    let!(:salary_payment_drafts) do
      salary_payment_drafts = SalaryPaymentDraft.where(payment_period_expense_id: community.get_open_period_expense)

      salary_payment_drafts.each do |draft|
        create_list(:discounts_draft, 2, salary_payment_draft: draft)
      end

      salary_payment_drafts
    end

    it 'should delete all associated discounts' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { DiscountsDraft.count }.from(DiscountsDraft.count).to(0)
    end

    it 'should not reset other values' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6)
    end

    it 'should set updater' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { full_time_employee_salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
    end

    it 'Should instantiate mesage' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@message)).to eq(
        { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      )
    end

    it 'Should instantiate redirection_path' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      open_period_expense = community.get_open_period_expense
      month = open_period_expense.month
      year = open_period_expense.year

      expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
        remuneration_salary_payment_drafts_path(month: month, year: year, tab: :discounts_days)
      )
    end

    context 'with filters' do
      let(:period_expense) { create(:period_expense, community: community) }
      let!(:another_part_time_employee_salary_payment_draft) do
        salary_payment_draft = create(
          :salary_payment_draft,
          worked_days: 10,
          bono_days: 8,
          extra_hour: 10,
          extra_hour_2: 8,
          extra_hour_3: 6,
          salary_id: part_time_salary.id,
          payment_period_expense_id: period_expense.id
        )

        create(:discounts_draft, salary_payment_draft: salary_payment_draft)

        salary_payment_draft
      end

      let(:params) { { community: community, tab: :discounts_days, part_time: true, user: user, month: period_expense.month, year: period_expense.year } }

      it 'should not delete discounts drafts that does not match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to_not change { full_time_employee_salary_payment_draft.reload.discounts_drafts.count }
          .from(full_time_employee_salary_payment_draft.discounts_drafts.count)
      end

      it 'should reset extra hours from salary payment drafts that match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { another_part_time_employee_salary_payment_draft.reload.discounts_drafts.count }
          .from(another_part_time_employee_salary_payment_draft.discounts_drafts.count).to(0)
      end

      it 'Should instantiate redirection_path' do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

        expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
          remuneration_salary_payment_drafts_path(month: period_expense.month, year: period_expense.year, tab: :discounts_days)
        )
      end
    end
  end

  describe 'when tab is :discounts' do
    let(:params) { { community: community, tab: :discounts, user: user } }
    let!(:salary_payment_drafts) do
      salary_payment_drafts = SalaryPaymentDraft.where(payment_period_expense_id: community.get_open_period_expense)

      salary_payment_drafts.each do |draft|
        create_list(:another_discounts_draft, 2, salary_payment_draft: draft)
      end

      salary_payment_drafts
    end

    it 'should delete all associated discounts' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { DiscountsDraft.another_discounts.count }.from(DiscountsDraft.another_discounts.count).to(0)
    end

    it 'should not reset other values' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6)
    end

    it 'should set updater' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { full_time_employee_salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
    end

    it 'Should instantiate mesage' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@message)).to eq(
        { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      )
    end

    it 'Should instantiate redirection_path' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      open_period_expense = community.get_open_period_expense
      month = open_period_expense.month
      year = open_period_expense.year

      expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
        remuneration_salary_payment_drafts_path(month: month, year: year, tab: :discounts)
      )
    end

    context 'with filters' do
      let(:period_expense) { create(:period_expense, community: community) }
      let!(:another_part_time_employee_salary_payment_draft) do
        salary_payment_draft = create(
          :salary_payment_draft,
          worked_days: 10,
          bono_days: 8,
          extra_hour: 10,
          extra_hour_2: 8,
          extra_hour_3: 6,
          salary_id: part_time_salary.id,
          payment_period_expense_id: period_expense.id
        )

        create(:another_discounts_draft, salary_payment_draft: salary_payment_draft)

        salary_payment_draft
      end

      let(:params) { { community: community, tab: :discounts, part_time: true, user: user, month: period_expense.month, year: period_expense.year } }

      it 'should not delete discounts drafts that does not match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to_not change { full_time_employee_salary_payment_draft.reload.discounts_drafts.another_discounts.count }
          .from(full_time_employee_salary_payment_draft.discounts_drafts.another_discounts.count)
      end

      it 'should reset extra hours from salary payment drafts that match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { another_part_time_employee_salary_payment_draft.reload.discounts_drafts.another_discounts.count }
          .from(another_part_time_employee_salary_payment_draft.discounts_drafts.another_discounts.count).to(0)
      end

      it 'Should instantiate redirection_path' do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

        expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
          remuneration_salary_payment_drafts_path(month: period_expense.month, year: period_expense.year, tab: :discounts)
        )
      end
    end
  end

  describe 'when tab is :bonus' do
    let(:params) { { community: community, tab: :bonus, user: user } }
    let!(:salary_payment_drafts) do
      salary_payment_drafts = SalaryPaymentDraft.where(payment_period_expense_id: community.get_open_period_expense)

      salary_payment_drafts.each do |draft|
        create_list(:bonus_draft, 2, salary_payment_draft: draft)
      end

      salary_payment_drafts
    end

    it 'should delete all associated bonus' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { BonusDraft.count }.from(BonusDraft.count).to(0)
    end

    it 'should not reset other values' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.worked_days }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.bono_days }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour }.from(10)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_2 }.from(8)

      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.not_to change { full_time_employee_salary_payment_draft.reload.extra_hour_3 }.from(6)
    end

    it 'should set updater' do
      expect do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
      end.to change { full_time_employee_salary_payment_draft.reload.updater_id }.from(nil).to(user.id)
    end

    it 'Should instantiate mesage' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@message)).to eq(
        { notice: I18n.t('views.remunerations.salary_payment_drafts.bulk_reset.success') }
      )
    end

    it 'Should instantiate redirection_path' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      open_period_expense = community.get_open_period_expense
      month = open_period_expense.month
      year = open_period_expense.year

      expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
        remuneration_salary_payment_drafts_path(month: month, year: year, tab: :bonus)
      )
    end

    context 'with filters' do
      let(:period_expense) { create(:period_expense, community: community) }
      let!(:another_part_time_employee_salary_payment_draft) do
        salary_payment_draft = create(
          :salary_payment_draft,
          worked_days: 10,
          bono_days: 8,
          extra_hour: 10,
          extra_hour_2: 8,
          extra_hour_3: 6,
          salary_id: part_time_salary.id,
          payment_period_expense_id: period_expense.id
        )

        create(:bonus_draft, salary_payment_draft: salary_payment_draft)

        salary_payment_draft
      end

      let(:params) { { community: community, tab: :bonus, part_time: true, user: user, month: period_expense.month, year: period_expense.year } }

      it 'should not delete bonus drafts that does not match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to_not change { full_time_employee_salary_payment_draft.reload.bonus_drafts.count }
          .from(full_time_employee_salary_payment_draft.bonus_drafts.count)
      end

      it 'should reset extra hours from salary payment drafts that match the filters' do
        expect do
          call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)
        end.to change { another_part_time_employee_salary_payment_draft.reload.bonus_drafts.count }
          .from(another_part_time_employee_salary_payment_draft.bonus_drafts.count).to(0)
      end

      it 'Should instantiate redirection_path' do
        call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

        expect(controller_context.instance_variable_get(:@redirection_path)).to eq(
          remuneration_salary_payment_drafts_path(month: period_expense.month, year: period_expense.year, tab: :bonus)
        )
      end
    end
  end
end
