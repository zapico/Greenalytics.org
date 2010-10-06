class UpdateEmissions < ActiveRecord::Migration
  def self.up
    change_table :emissions do |t|
      t.column :visitors, :integer
      t.column :time, :decimal, :precision => '10'
    end
  end

  def self.down
  end
end
