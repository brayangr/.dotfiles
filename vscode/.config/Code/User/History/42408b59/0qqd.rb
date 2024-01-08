require 'rails_helper'

RSpec.describe SalaryPayments::SalaryPaymentDirector do
  describe '#build' do
    let!(:community) { create(:chilean_community, :with_initial_period) }
    let!(:period_expense) { community.period_expenses.first }

    context 'when called with a employee without draft for the payment period' do
      let!(:employee) { create(:full_time_employee, community: community) }
      let!(:last_salary_payment) do
        create(
          :salary_payment,
          :with_spouse_data,
          :with_employee_protection_law,
          :with_adjust_by_rounding,
          :with_discounts,
          salary: employee.active_salary,
          validated: true
        )
      end
      let!(:bonus) { create(:salary_additional_info, :bonus, salary_payment_id: last_salary_payment.id) }

      it 'should uses SalaryPayments::FullTimeBuilder' do
        expect(SalaryPayments::FullTimeBuilder).to receive(:new).with(
          employee: employee,
          last_salary_payment: last_salary_payment,
          payment_period_expense: period_expense,
          period_expense: period_expense,
          salary: employee.active_salary
        ).and_return(
          SalaryPayments::FullTimeBuilder.new(employee: employee,
                                              last_salary_payment: last_salary_payment,
                                              payment_period_expense: period_expense,
                                              period_expense: period_expense,
                                              salary: employee.active_salary)
        )

        described_class.new(
          employee: employee,
          payment_period_expense: period_expense,
          period_expense: period_expense
        ).build
      end

      it 'should return an instance of SalaryPayment' do
        salary_payment = described_class.new(
          employee: employee,
          payment_period_expense: period_expense,
          period_expense: period_expense
        ).build

        expect(salary_payment).to be_a(SalaryPayment)
      end

      context 'when there are a previous salary payment' do
        it 'should copy the identification data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.salary_id).to be(employee.active_salary.id)
          expect(salary_payment.payment_period_expense_id).to be(period_expense.id)
          expect(salary_payment.period_expense_id).to be(period_expense.id)
          expect(salary_payment.aliquot_id).to be(last_salary_payment.aliquot_id)
        end

        it 'should copy the worked days data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.worked_days).to eq(30)
        end

        it 'should copy the assignments data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.allocation_tool_wear).to eq(last_salary_payment.allocation_tool_wear)
          expect(salary_payment.lost_cash_allocation).to eq(last_salary_payment.lost_cash_allocation)
        end

        it 'should copy the bonus data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.advance_gratifications).to eq(last_salary_payment.advance_gratifications)
          expect(salary_payment.anual_gratifications).to eq(last_salary_payment.anual_gratifications)
          expect(salary_payment.bono_responsabilidad).to eq(last_salary_payment.bono_responsabilidad)

          expect(salary_payment.salary_additional_infos.reject(&:discount).count).to eq(1)

          new_bonus = salary_payment.salary_additional_infos.reject(&:discount).first

          expect(new_bonus.name).to eq(bonus.name)
          expect(new_bonus.value).to eq(bonus.value)
        end

        it 'should copy the discounts data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.union_fee).to eq(last_salary_payment.union_fee)
          expect(salary_payment.legal_holds).to eq(last_salary_payment.legal_holds)
        end

        it 'should copy the apv data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.apv).to eq(last_salary_payment.apv)
          expect(salary_payment.cotizacion_empleador_apvc).to eq(last_salary_payment.cotizacion_empleador_apvc)
          expect(salary_payment.cotizacion_trabajador_apvc).to eq(last_salary_payment.cotizacion_trabajador_apvc)
        end

        it 'should copy the partner data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.spouse).to eq(last_salary_payment.spouse)
          expect(salary_payment.spouse_voluntary_amount).to eq(last_salary_payment.spouse_voluntary_amount)
          expect(salary_payment.spouse_periods_number).to eq(last_salary_payment.spouse_periods_number)
          expect(salary_payment.spouse_capitalizacion_voluntaria).to eq(last_salary_payment.spouse_capitalizacion_voluntaria)
        end

        it 'should copy the employment protection law data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.employee_protection_law).to eq(last_salary_payment.employee_protection_law)
          expect(salary_payment.protection_law_code).to eq(last_salary_payment.protection_law_code)
          expect(salary_payment.suspension_or_reduction_days).to eq(last_salary_payment.suspension_or_reduction_days)
          expect(salary_payment.reduction_percentage).to eq(last_salary_payment.reduction_percentage)
          expect(salary_payment.afc_informed_rent).to eq(last_salary_payment.afc_informed_rent)
        end

        it 'should copy the cash payment data' do
          salary_payment = described_class.new(
            employee: employee,
            payment_period_expense: period_expense,
            period_expense: period_expense
          ).build

          expect(salary_payment.adjust_by_rounding).to eq(last_salary_payment.adjust_by_rounding)
        end
      end

      context 'when there are no previous salary payment' do
      end
    end
  end
end
