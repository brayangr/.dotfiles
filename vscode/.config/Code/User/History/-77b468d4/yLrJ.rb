# == Schema Information
#
# Table name: discounts_drafts
#
#  id                      :bigint           not null, primary key
#  days                    :integer          default(0)
#  end_date                :date
#  hours                   :integer          default(0)
#  reason                  :integer          default(0)
#  start_date              :date
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  salary_payment_draft_id :bigint           not null
#
# Indexes
#
#  index_discounts_drafts_on_salary_payment_draft_id  (salary_payment_draft_id)
#
# Foreign Keys
#
#  fk_rails_7bdfed0c03  (salary_payment_draft_id => salary_payment_drafts.id)
#
class DiscountsDraft < ApplicationRecord
  belongs_to :salary_payment_draft

  enum :reason, {
    without_movements: 0,
    permanent_contract: 1,
    archived: 2,
    trashed: 3
  }
end
