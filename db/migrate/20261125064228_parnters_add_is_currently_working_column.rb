class ParntersAddIsCurrentlyWorkingColumn < ActiveRecord::Migration[8.1]
  def change
    add_column :partners, :is_currently_working, :boolean, default: false, null: false
  end
end
