class Changetotaltime < ActiveRecord::Migration
  def self.up
    remove_column :emissions, :time
    remove_column :emissions, :co2_server
    remove_column :emissions, :co2_users  
    remove_column :emissions, :factor
    remove_column :emissions, :traffic
        
    change_table :emissions do |t|
      
      t.column :traffic, :integer
      t.column :co2_server, :decimal, :precision => '40', :scale => '5'
      t.column :co2_users, :decimal, :precision => '40', :scale => '5'
      t.column :time, :decimal, :precision => '20', :scale => '2'
      t.column :factor, :decimal, :precision => '10', :scale => '5'
    end
  end
  

  def self.down
  end
end
