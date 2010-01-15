class SitesController < ApplicationController
 require 'rubygems'
 require 'rugalytics'
 require 'universal_ruby_whois' 
 require 'whois'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gattica'
 
 def test
    #Garb::Session.login('jorgezapico@gmail.com', 'rip2maQ1')
    #Garb::Account.all.first
    #@profile = Garb::Profile.all
    
    Rugalytics.login 'jorgezapico@gmail.com', 'rip2maQ1'
    @profile = Rugalytics.find_profile('Verde media','carbon.to')
    
     today= DateTime.now-1.days
     amonthago = today-30.days
     today = today.strftime("%Y-%m-%d")
     amonthago = amonthago.strftime("%Y-%m-%d")
     gs = Gattica.new({:email => 'jorgezapico@gmail.com', :password => 'rip2maQ1', :profile_id => 21441200})
     @results = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'pagePath', :metrics => 'pageviews'})
     # Get the time on site by country
     visitors = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'country', :metrics => 'timeOnSite', :aggregates => 'country'})
     
   
     # Parse the time on site by country 
     @visitors_text = " "
     @time = 0 
     @totalco2 = 0
     visitors.points.each do |country|
       # Parse country
       name = country.to_s.split('ga:country=')[1]
       name = name.to_s.split('"')[0]
       # Get carbon factor
       factor = ""
       if name != "(not set)" then
         h_name = name.sub(" ", "%20")
         carma = Net::HTTP.get(URI.parse("http://carma.org/api/1.1/searchLocations?region_type=2&name="+h_name+"&format=json"))
         # Parse the factor from Json string
         factor = carma.to_s.split("intensity")[1]
         factor = factor.to_s.split('present" : "')[1] 
         factor = factor.to_s.split('",')[0]
       end
       if factor == "" then
         factor = "0.501"
       end
       # Parse time
       time = country.to_s.split(":timeOnSite=>")[1]
       time = time.to_s.split("}")[0]
       @time += time.to_i
       
       # Calculate the impact
       carbonimpact = factor.to_f * time.to_i * 20 / 3600000
       @totalco2 += carbonimpact
       
       # Aggregate
       time = (time.to_f/60).round(1)
       grams = carbonimpact.round(2)
       if grams != 0
         text = "<b>" + name.to_s + "</b> " + time.to_s + " min "+ grams.to_s + " grams CO2. <br/>"
         @visitors_text += text
       end
     end     
     
     @time = @time/60
     
     @main_url = "http://carbon.to"
    
    # Get HTML Size
    @length = open(@main_url).length
    
    @hp = Hpricot(open(@main_url))
    
    @pictures_size = 0
    # Get images size
    @hp.search("img").each do |p|
      picurl = @main_url+p.attributes['src']
      @pictures_size += open(picurl).length
    end
     
     @scripts = 0
     # Get CSS size
     @hp.search("link").each do |p|
      cssurl = @main_url+p.attributes['href']
      @scripts += open(cssurl).length
    end
    # Get script size
    @hp.search("html/head//script").each do |p|
      scripturl = @main_url+p.attributes['src']
      @scripts += open(scripturl).length
    end
    

    
    @w = Whois::Client.new
    @w.query('70.32.99.240')

 
 end

end