desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
    sites = Site.find(:all)
    date_end = DateTime.now
    nrday = date_end.day.to_i
    nrday -= 1
    date_start = DateTime.now-nrday.days
    sites.each do |si|  
      CalculateSite.new(si.id,date_start,date_end)
    end
end
