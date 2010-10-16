class CalculateSite
  attr_accessor :site_id
  attr_accessor :date_start
  attr_accessor :date_end
  
  def initialize(site_id,date_start,date_end)
    self.site_id = site_id
    self.date_start = date_start
    self.date_end = date_end
  end
  
  def perform
    site = Site.find(site_id)
    site.calculate_month(site_id,date_start,date_end)
    puts "Calculation completed"
  end 
 
 end