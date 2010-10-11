class Changeemissions < ActiveRecord::Migration
  def self.up
    change_table :emissions do |t|
      t.column :traffic, :decimal, :precision => '10'
      t.column :server_location, :string
      t.column :factor, :decimal, :precision => '10'
    end
    remove_column :emissions, :co2_infra
    remove_column :emissions, :text_infra
    remove_column :emissions, :text_server
  end

  def self.down
  end
end
