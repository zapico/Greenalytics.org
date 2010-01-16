class SitesController < ApplicationController
 require 'rubygems'
 require 'rugalytics'
 require 'universal_ruby_whois' 
 require 'whois'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gattica'
 
 def login
   if request.post?
       e = "jorgezapico@gmail.com"
       p = "rip2maQ1"
       @gattica = Gattica.new({:email => e, :password => p})
       if @gattica 
           redirect_to(:action => "select")
       else
          flash[:notice] = "Invalid user/password combination"
       end
     end
 end
 def select
    e = "jorgezapico@gmail.com"
    p = "rip2maQ1"
    @gattica = Gattica.new({:email => e, :password => p})
    @accounts =  @gattica.accounts
    
 end
 
 def test
         
     # GET DATA FROM GOOGLE ANALYTICS
     today= DateTime.now-1.days
     amonthago = today-30.days
     today = today.strftime("%Y-%m-%d")
     amonthago = amonthago.strftime("%Y-%m-%d")
     
     gs = Gattica.new({:email => 'jorgezapico@gmail.com', :password => 'rip2maQ1'})
     gs.profile_id = params[:site_id]
     # Get the pageview of all apges
     allpages = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'pagePath', :metrics => 'pageviews'})
     # Get the time on site by country
     visitors = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'country', :metrics => 'timeOnSite', :aggregates => 'country'})
     # Get address (Not as easy as it should be!)
     address = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'hostname', :metrics => 'pageviews',:sort => '-pageviews', :aggregates => 'hostame'})
     @address = address.points.first.dimensions
     @address = @address.to_s.split('hostname')[1]
     @address = "http://"+@address.to_s
     
     # CALCULATE VISITORS IMPACT
     # Parse the time on site by country 
     @visitors_text = " "
     @time = 0 
     @co2_visitors = 0
     visitors.points.each do |country|
       # Parse country
       name = country.to_s.split('ga:country=')[1]
       name = name.to_s.split('"')[0]
       # Get carbon factor
       factor = ""
       if name != "(not set)" then
         h_name = name.gsub(" ", "%20")
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
       @co2_visitors += carbonimpact
       
       # Aggregate
       time = (time.to_f/60).round(1)
       grams = carbonimpact.round(2)
       if grams != 0
         text = "<b>" + name.to_s + "</b> " + time.to_s + " min "+ grams.to_s + " grams CO2. <br/>"
         @visitors_text += text
       end
     end     
     
     @co2_visitors = @co2_visitors/1000
     @time = @time/60
     


    # CALCULATE TOTAL TRAFFIC
    # Initialiate variables
    @total_size = 0
    @page_text = ""
    # Iterate through the different pages
    allpages.points.each do |point|
    	# 1. Get the URL
    	url = point.to_s.split("pagePath=>")[1]
    	url = url.to_s.split("}")[0]
    	url = url.to_s.split('"')[1]
    	url = url.to_s.split('"')[0]
    	# 2. Get the number of visitors
    	visits = point.to_s.split("pageviews=>")[1]
    	visits = visits.to_s.split("}")[0]
    	# 3. Aggregate text
    	pagesize = pageSize(@address+url)/1024
    	@page_text += "<p><b>" + url  + "</b></p>"
    	@page_text += "<p>" + pagesize.to_s + " kb. " +visits.to_s+ " visitors</p>"
    	@total_size += pagesize*visits.to_i
    end
   
    # CALCULATE SERVER AND INFRA IMPACT
    @co2_server = 0
    @co2_infrastructure = 0
    @co2_server = @total_size*0.000001*8*16*0.501
    
    @w = Whois::Client.new
    @w.query('70.32.99.240')
    
    # Aggregate total CO2
    @total_co2= 0
    @total_co2 = @co2_visitors + @co2_server
 
    # CREATE PIE GRAPHIC
    per_visitors = @co2_visitors*100/@total_co2
    per_server = @co2_server*100/@total_co2
    @grafico="http://chart.apis.google.com/chart?chs=250x100&amp;chd=t:"+per_visitors.to_s+","+per_server.to_s+"&amp;cht=p3&amp;chl=Visitors|Server"
 
    # TRANSLATE USING CARBON.TO
    beer = Net::HTTP.get(URI.parse("http://carbon.to/beers.json?co2="+@total_co2.round.to_s))
    beer = ActiveSupport::JSON.decode(beer)
    @beeramount = beer["conversion"]["amount"]
    car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+@total_co2.round.to_s))
    car = ActiveSupport::JSON.decode(car)
    @caramount = car["conversion"]["amount"]
 
 end
 
 # Gives back the page size of a URL
 def pageSize (url)
    # Get HTML Size
   total = 0
   begin
   total = open(url).length
   
   hp = Hpricot(open(url))
   
   # Get images size
   hp.search("img").each do |p|
     picurl = url+p.attributes['src']
     total += open(picurl).length
   end
    # Get CSS size
    hp.search("link").each do |p|
     cssurl = url+p.attributes['href']
     total += open(cssurl).length
   end
   # Get script size
     hp.search("html/head//script").each do |p|
     scripturl = url+p.attributes['src']
     total += open(scripturl).length
   end
   ensure
   return total
   end
 end
 

end