class CreateAudits < ActiveRecord::Migration[6.1]
  def change
    create_table :audits do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :integer
      t.column :message, :string
      t.column :audited_changes, :string
      t.timestamps
    end
    add_index :audits, [:auditable_type, :auditable_id], :name => 'auditable_index'
  end
end
