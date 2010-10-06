class CreateEmissions < ActiveRecord::Migration
  def self.up
    create_table :emissions do |t|
      t.column :co2_server, :decimal, :precision => '10'
      t.column :co2_infra, :decimal, :precision => '10'
      t.column :co2_users, :decimal, :precision => '10'
      t.column :site_id, :integer
      t.column :date_start, :date
      t.column :date_end, :date
      t.column :text_server, :text
      t.column :text_infra, :text
      t.column :text_users, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :emissions
  end
end
