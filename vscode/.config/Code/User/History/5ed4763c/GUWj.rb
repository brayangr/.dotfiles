class AddFieldsToDiscountsDraft < ActiveRecord::Migration[7.0]
  def change
    add_column :discounts_drafts, :amount, :integer, default: 0
    add_column :discounts_drafts, :description, :string
  end
end
