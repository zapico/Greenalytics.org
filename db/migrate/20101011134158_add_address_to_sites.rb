class AddAddressToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :address, :string
  end

  def self.down
    remove_column :sites, :address
  end
end
