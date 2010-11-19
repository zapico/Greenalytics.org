class AddPublicToSites < ActiveRecord::Migration
  def self.up
    change_table :sites do |t|   
      t.column :ispublic, :boolean
    end
  end

  def self.down
  end
end
