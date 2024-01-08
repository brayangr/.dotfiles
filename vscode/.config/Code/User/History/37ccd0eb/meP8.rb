require 'rails_helper'
require 'support/shared_examples/standard_service_object_examples'
require 'support/shared_examples/standard_service_object_subclass_examples'

RSpec.describe Remuneration::SalaryPaymentDrafts::IndexResponse do
  include StandardServiceObjectsHelper

  it_behaves_like :standard_service_object
  it_behaves_like :standard_service_object_subclass

  let(:controller_context) { Remuneration::SalaryPaymentDraftsController.new }

  describe 'When tab is :worked_days' do
    let(:params) { { community: community } }

    it 'Should instantiate index' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@index)).to be_a(Symbol)
    end

    it 'Should instantiate payment_period_expense' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@payment_period_expense)).to be_a(PeriodExpense)
    end

    it 'Should instantiate month' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@month)).to be_a(Integer)
    end

    it 'Should instantiate year' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@year)).to be_a(Integer)
    end

    it 'Should instantiate employee_finder' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@employee_finder)).to be_a(String)
    end

    it 'Should instantiate employees' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@employees)).to be_a(ActiveRecord::Relation)
    end

    it 'Should instantiate salaries' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@salaries)).to be_a(Hash)
    end

    it 'Should instantiate salary_payment_drafts' do
      call_service_object(service_object: described_class, instantiate_context: controller_context, params: params)

      expect(controller_context.instance_variable_get(:@salary_payment_drafts)).to be_a(Hash)
    end
  end

  describe 'Should return expected records' do
    let(:actual_period) { community.get_open_period_expense.period }

    let!(:full_time_salary) { create(:salary, community: community, daily_wage: false, start_date: actual_period - 10.month, active: true) }
    let!(:part_time_salary) { create(:salary, community: community, daily_wage: true, start_date: actual_period - 5.month, active: true) }
    let!(:part_time_fired_salary) { create(:salary, community: community, daily_wage: true, start_date: actual_period - 10.month, active: true) }

    let!(:full_time_employee) { full_time_salary.employee }
    let!(:part_time_employee) { part_time_salary.employee }
    let!(:part_time_fired_employee) { part_time_fired_salary.employee }
    let!(:part_time_fired_finiquito) { create(:finiquito, employee: part_time_fired_employee, salary: part_time_fired_salary, start_date: actual_period - 10.month, end_date: actual_period - 3.month - 1.day) }

    let(:params) do
      {
        community: community,
        employee_finder: nil,
        month: nil,
        year: nil,
        part_time: true
      }
    end

    context 'When no filter are applied' do
      it 'Should get part-time employees in actual period' do
        response = call_service_object(service_object: described_class, params: params)

        expect(response.data[:employees]).to include(part_time_employee)
        expect(response.data[:employees]).not_to include(full_time_employee)
        expect(response.data[:employees]).not_to include(part_time_fired_employee)
        expect(response.data[:salaries]).to include({ part_time_employee.id => part_time_salary })
        expect(response.data[:salary_payment_drafts]).to be_empty
      end
    end

    context 'When month and year filters are applied' do
      it 'Should get part-time employees 4 months ago' do
        params[:month] = (actual_period - 4.month).month
        params[:year] = actual_period.year

        response = call_service_object(service_object: described_class, params: params)

        expect(response.data[:employees]).to include(part_time_employee)
        expect(response.data[:employees]).not_to include(full_time_employee)
        expect(response.data[:employees]).to include(part_time_fired_employee)
        expect(response.data[:salaries]).to include({ part_time_employee.id => part_time_salary, part_time_fired_employee.id => part_time_fired_salary })
        expect(response.data[:salary_payment_drafts]).to be_empty
      end

      it 'Should get part-time employees 4 months ago' do
        params[:month] = (actual_period - 3.month).month
        params[:year] = actual_period.year

        response = call_service_object(service_object: described_class, params: params)

        expect(response.data[:employees]).to include(part_time_employee)
        expect(response.data[:employees]).not_to include(full_time_employee)
        expect(response.data[:employees]).not_to include(part_time_fired_employee)
        expect(response.data[:salaries]).to include({ part_time_employee.id => part_time_salary })
        expect(response.data[:salary_payment_drafts]).to be_empty
      end
    end

    context 'When name filter is applied' do
      it 'Should get part-time employees with searched name' do
        params[:month] = (actual_period - 4.month).month
        params[:year] = actual_period.year
        params[:employee_finder] = "#{part_time_fired_employee.first_name} #{part_time_fired_employee.father_last_name}"

        response = call_service_object(service_object: described_class, params: params)

        expect(response.data[:employees]).not_to include(part_time_employee)
        expect(response.data[:employees]).not_to include(full_time_employee)
        expect(response.data[:employees]).to include(part_time_fired_employee)
        expect(response.data[:salaries]).to include({ part_time_fired_employee.id => part_time_fired_salary })
        expect(response.data[:salary_payment_drafts]).to be_empty
      end
    end
  end
end
