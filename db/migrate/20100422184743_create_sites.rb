class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.column :name, :string, :limit => 100
      t.column :gid, :string, :limit => 40
      t.timestamps
    end
  end

  def self.down
    drop_table :sites
  end
end
