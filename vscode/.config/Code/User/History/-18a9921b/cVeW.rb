class CreateSalaryPaymentDrafts < ActiveRecord::Migration[7.0]
  def change
    create_table :salary_payment_drafts do |t|
      t.references :salary, null: false, foreign_key: true
      t.references :payment_period_expense, null: false, foreign_key: { to_table: :period_expenses }
      t.references :creator, polimorphic: true
      t.references :updater, polimorphic: true
      t.integer :extra_hour, default: 0
      t.integer :extra_hour_2, default: 0
      t.integer :extra_hour_3, default: 0
      t.integer :worked_days, default: 0
      t.integer :bono_days, default: 0

      t.timestamps
    end
  end
end
