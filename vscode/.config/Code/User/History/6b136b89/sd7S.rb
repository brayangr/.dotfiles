# == Schema Information
#
# Table name: salary_payment_drafts
#
#  id                        :bigint           not null, primary key
#  bono_days                 :integer          default(0)
#  extra_hour                :integer          default(0)
#  extra_hour_2              :integer          default(0)
#  extra_hour_3              :integer          default(0)
#  worked_days               :integer          default(0)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  creator_id                :bigint
#  payment_period_expense_id :bigint           not null
#  salary_id                 :bigint           not null
#  updater_id                :bigint
#
# Indexes
#
#  index_salary_payment_drafts_on_creator_id                 (creator_id)
#  index_salary_payment_drafts_on_payment_period_expense_id  (payment_period_expense_id)
#  index_salary_payment_drafts_on_salary_id                  (salary_id)
#  index_salary_payment_drafts_on_updater_id                 (updater_id)
#
# Foreign Keys
#
#  fk_rails_08f679c8f3  (payment_period_expense_id => period_expenses.id)
#  fk_rails_4e9a293732  (salary_id => salaries.id)
#
class SalaryPaymentDraft < ApplicationRecord
  belongs_to :salary
  belongs_to :payment_period_expense, class_name: 'PeriodExpense'
  has_many :license_drafts, dependent: :destroy
  has_many :discounts_drafts, dependent: :destroy
  has_many :bonus_drafts, dependent: :destroy

  accepts_nested_attributes_for :license_drafts, allow_destroy: true
  accepts_nested_attributes_for :discounts_drafts, allow_destroy: true
  accepts_nested_attributes_for :bonus_drafts, allow_destroy: true
end
