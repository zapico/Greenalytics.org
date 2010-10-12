class Changetime < ActiveRecord::Migration
    def self.up
      change_table :emissions do |t|
        t.column :year, :integer
        t.column :month, :integer
      end
      remove_column :emissions, :date_start
      remove_column :emissions, :date_end
    end

  def self.down
  end
end
