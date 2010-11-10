class AddAvgsizeToSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|
      
      t.column :avgsize, :integer
    end
  end

  def self.down
  end
end
