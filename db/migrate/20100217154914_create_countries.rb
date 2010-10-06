class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table "countries", :force => true do |t|
      t.column :name, :string, :limit => 40
      t.column :factor, :float
      t.timestamps
    end
  end

  def self.down
    drop_table :countries
  end
end
