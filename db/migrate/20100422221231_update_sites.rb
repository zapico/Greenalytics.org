class UpdateSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|
      t.column :user_id, :integer
    end
  end

  def self.down
  end
end
