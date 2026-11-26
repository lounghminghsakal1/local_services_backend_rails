class CreatePartnerServices < ActiveRecord::Migration[8.1]
  def change
    create_table :partner_services do |t|
      t.references :partner, null: false, foreign_key: true
      t.references :service_category, null: false, foreign_key: true
      t.string :experience
      t.boolean :is_active


      t.timestamps
    end
  end
end
