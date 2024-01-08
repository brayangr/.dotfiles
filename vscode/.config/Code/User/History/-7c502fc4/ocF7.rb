class AddAssociationToDiscountsDraft < ActiveRecord::Migration[7.0]
  def change
    add_reference :discounts_drafts, :salary_payment_draft, null: false, foreign_key: true
  end
end
