class SitesController < ApplicationController
 require 'rubygems'
 require 'whois'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gdata'
 
 def login
   if session[:token]
     reset_session 
   end
   scope = 'https://www.google.com/analytics/feeds/'
   #next_url = 'http://localhost:3000/sites/select'
   next_url = 'http://greenalytics.org/sites/select'
   secure = false  # set secure = true for signed AuthSub requests
   sess = true
   @authsub_link = GData::Auth::AuthSub.get_url(next_url, scope, secure, sess)
 end
 def select
   
   client = GData::Client::GBase.new
   if session[:token]
     client.authsub_token = session[:token]
   else
     if params[:token]
       client.authsub_token = params[:token] # extract the single-use token from the URL query params
       session[:token] = client.auth_handler.upgrade()
       client.authsub_token = session[:token] if session[:token]
     else
       redirect_to :action => "login"
     end
   end
   begin
     @feed = client.get('https://www.google.com/analytics/feeds/accounts/default').to_xml
   rescue Exception => exc
      logger.error("Message for the log file #{exc.message}")
      flash[:notice] = "No google analytics connected to this account"
      redirect_to :action => "login"
   end
   
 end
 
 # MAIN FUNCTION THAT CALCULATES THE FOOTPRINT
 def calculate_old
     
     # Create a client and login using session   
     client = GData::Client::GBase.new
     client.authsub_token = session[:token] if session[:token]
     profile_id = params[:site_id]
     
     # GET DATA FROM GOOGLE ANALYTICS
     @today= DateTime.now-1.days
     @amonthago = @today-30.days
     @today = @today.strftime("%Y-%m-%d")
     @amonthago = @amonthago.strftime("%Y-%m-%d")
     
     profile_id = params[:site_id]
     # Get the pageview of all apges
     #allpages = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'pagePath', :metrics => 'pageviews'})
     #allpages = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:pagePath&metrics=ga:pageviews&start-date='+@amonthago+'&end-date='+@today).to_xml
     allpages = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&metrics=ga:visits&start-date='+@amonthago+'&end-date='+@today).to_xml
     # Get the time on site by country
     #visitors = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'country', :metrics => 'timeOnSite', :aggregates => 'country'})
     visitors = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:country&metrics=ga:timeOnSite&start-date='+@amonthago+'&end-date='+@today+'&aggregates=ga:country').to_xml
     # Get address (Not as easy as it should be!)
     #address = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'hostname', :metrics => 'pageviews',:sort => '-pageviews', :aggregates => 'hostame'})
     address = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:hostname&metrics=ga:pageviews&start-date='+@amonthago+'&end-date='+@today+'&sort=-ga:pageviews&aggregates=ga:hostname').to_xml
     address = address.to_s.split("dxp:dimension name='ga:hostname' value='")[1]
     address = address.to_s.split("'")[0]
     @address = "http://"+address.to_s
      
     # CALCULATE TOTAL TRAFFIC
     # Initialiate variables
     @total_size = 0
     totalvisits = 0
     @page_text = ""
     # Iterate through the different pages
   	 pagesize = pageSize(@address)/1024
     totalvisits = allpages.elements["dxp:aggregates"].elements["dxp:metric name='ga:visits'"].attribute("value").value
     
     #allpages.elements.each('entry') do |point|
     # 1. Get the URL
     #	url = point.elements["dxp:dimension name='ga:pagePath'"].attribute("value").value
     # 2. Get the number of visitors
     #	visits = point.elements["dxp:metric name='ga:pageviews'"].attribute("value").value
     # 3. Aggregate text
     #if visits.to_i > 1 then
     # pagesize = pageSize(@address+url)/1024
   	 # end
   	 # totalvisits += visits.to_i
     # end
   	 @page_text += "<p> Pages size " + pagesize.to_s + " kB. " +totalvisits.to_s+ " visitors</p>"
     @total_size = pagesize*totalvisits.to_i  
      
            
     # CALCULATE VISITORS IMPACT
      # Parse the time on site by country 
      @visitors_text = " "
      @time = 0 
      @co2_visitors = 0
      @totalvisitors = 0
      visitors.elements.each('entry') do |land|
        # Parse country
        name = land.elements["dxp:dimension name='ga:country'"].attribute("value").value
        # Get carbon factor
        factor = ""
        # See if it exists in our database
        if Country.find(:first,:conditions => [ "name = ?", name ]) then
          factor=Country.find(:first,:conditions => [ "name = ?", name ]).factor
        else
        if name then
          h_name = name.gsub(" ", "%20")
          begin
          carma = Net::HTTP.get(URI.parse("http://carma.org/api/1.1/searchLocations?region_type=2&name="+h_name+"&format=json"))
          # Parse the factor from Json string
          factor = carma.to_s.split("intensity")[1]
          factor = factor.to_s.split('present" : "')[1] 
          factor = factor.to_s.split('",')[0]
          rescue Exception => exc
            factor = "0.501"
          end
        end
        #Save in our database
        c = Country.new()
        c.name = name
        c.factor = factor
        c.save
        end
        if factor == "" then
          factor = "0.501"
        end
        # Parse time  
        time = land.elements["dxp:metric name=ga:'timeOnSite'"].attribute("value").value
        @time += time.to_i

        # Calculate the impact
        carbonimpact = factor.to_f * time.to_i * 35.55 / 3600000
        @co2_visitors += carbonimpact
        
        # Aggregate
        time = (time.to_f/60).round(1)
        grams = carbonimpact.round(2)
        if grams != 0
          text = "<b>" + name.to_s + "</b> " + time.to_s + " min "+ grams.to_s + " grams CO2. With a factor of "+factor.to_f.round(2).to_s+"<br/>"
          @visitors_text += text
        end
      end     

      @co2_visitors = @co2_visitors/1000
      @time = @time/60

    # CALCULATE SERVER AND INFRA IMPACT
    @co2_server = 0
    @co2_server = @total_size * 9 * 0.501
    @co2_server = @co2_server /  1048576
    
    # @w = Whois::Client.new
    # @w.query('70.32.99.240')
    
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
 
 def calculate
    
     # Create a client and login using session   
     client = GData::Client::GBase.new
     client.authsub_token = session[:token] if session[:token]
     profile_id = params[:site_id]
     @today= DateTime.now-1.days
     @amonthago = @today-30.days
     @today = @today.strftime("%Y-%m-%d")
     @amonthago = @amonthago.strftime("%Y-%m-%d")
     # Get address (Not as easy as it should be!)
     address = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:hostname&metrics=ga:pageviews&start-date='+@amonthago+'&end-date='+@today+'&sort=-ga:pageviews&aggregates=ga:hostname').to_xml
     address = address.to_s.split("dxp:dimension name='ga:hostname' value='")[1]
     address = address.to_s.split("'")[0]
     @address = "http://"+address.to_s
     
     @total_co2 = 0.00
     @total_size = 0.00
     @co2_visitors = 0.00
     @co2_server = 0.00
     @time = 0.00
     @beeramount = 0.00
     @grafico = ""
     @page_text = ""
     @visitors_text = ""
     @caramount = 0.00
     @grampervisitor = 0.00
      
 end
 
 def calculate_total
    
    begin
    # Create a client and login using session   
     client = GData::Client::GBase.new
     client.authsub_token = session[:token] if session[:token]
     profile_id = params[:site_id]
     
     # GET DATA FROM GOOGLE ANALYTICS
     @today= DateTime.now-1.days
     @amonthago = @today-30.days
     @today = @today.strftime("%Y-%m-%d")
     @amonthago = @amonthago.strftime("%Y-%m-%d")
      
     # Get the pageview of all apges
     allpages = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&metrics=ga:visits&start-date='+@amonthago+'&end-date='+@today).to_xml

     # CALCULATE TOTAL TRAFFIC
     # Initialiate variables
     @total_size = 0
     totalvisits = 0
     @page_text = ""
     # Iterate through the different pages
   	 pagesize = pageSize(params[:address])/1024
     totalvisits = allpages.elements["dxp:aggregates"].elements["dxp:metric name='ga:visits'"].attribute("value").value
   	 @page_text += "<p> Pages size " + pagesize.to_s + " kB. " +totalvisits.to_s+ " visitors</p>"
     @total_size = pagesize*totalvisits.to_i 
     
     # CALCULATE SERVER AND INFRA IMPACT
     @co2_server = 0
     @co2_server = @total_size * 9 * 0.501
     @co2_server = @co2_server /  1048576
   
   #visitors = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'country', :metrics => 'timeOnSite', :aggregates => 'country'})
   visitors = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:country&metrics=ga:timeOnSite&start-date='+@amonthago+'&end-date='+@today+'&aggregates=ga:country').to_xml
              
   # CALCULATE VISITORS IMPACT
    # Parse the time on site by country 
    @visitors_text = " "
    @time = 0 
    @co2_visitors = 0
    @totalvisitors = 0
    visitors.elements.each('entry') do |land|
      # Parse country
      name = land.elements["dxp:dimension name='ga:country'"].attribute("value").value
      # Get carbon factor
      factor = ""
      # See if it exists in our database
      if Country.find(:first,:conditions => [ "name = ?", name ]) then
        factor=Country.find(:first,:conditions => [ "name = ?", name ]).factor
      else
      if name then
        h_name = name.gsub(" ", "%20")
        begin
        carma = Net::HTTP.get(URI.parse("http://carma.org/api/1.1/searchLocations?region_type=2&name="+h_name+"&format=json"))
        # Parse the factor from Json string
        factor = carma.to_s.split("intensity")[1]
        factor = factor.to_s.split('present" : "')[1] 
        factor = factor.to_s.split('",')[0]
        rescue Exception => exc
          factor = "0.501"
        end
      end
      #Save in our database
      c = Country.new()
      c.name = name
      c.factor = factor
      c.save
      end
      if factor == "" then
        factor = "0.501"
      end
      # Parse time  
      time = land.elements["dxp:metric name=ga:'timeOnSite'"].attribute("value").value
      @time += time.to_i

      # Calculate the impact
      carbonimpact = factor.to_f * time.to_i * 35.55 / 3600000
      @co2_visitors += carbonimpact
      
      # Aggregate
      time = (time.to_f/60).round(1)
      grams = carbonimpact.round(2)
      if grams != 0
        text = "<b>" + name.to_s + "</b> " + time.to_s + " min "+ grams.to_s + " grams CO2. With a factor of "+factor.to_f.round(2).to_s+"<br/>"
        @visitors_text += text
      end
    end     

   @co2_visitors = @co2_visitors/1000
   @time = @time/60
    
   # Aggregate total CO2
   @total_co2= 0.00
   @total_co2 = @co2_visitors + @co2_server
   
   @grampervisitor = 0.00
   if totalvisits.to_i != 0
    @grampervisitor = @total_co2.to_f / totalvisits.to_i
    @grampervisitor = @grampervisitor*1000
   end
   
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
    
    rescue Exception => exc
       redirect_to :action => "select"
     end
     render(:partial => "calculate")
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
     picurl = picurl = p.attributes['src'].to_s
     if picurl[0..3] != "http"
       picurl = url+picurl
     end
     total += open(picurl).length
   end
    # Get CSS size
    hp.search("link").each do |p|
      cssurl = p.attributes['href'].to_s
      if cssurl[0..3] != "http"
           cssurl = url+cssurl
        end
        total += open(cssurl).length
   end
   # Get script size
     hp.search("html/head//script").each do |p|
       scripturl = p.attributes['src'].to_s
       if scripturl[0..3] != "http"
             scripturl = url+scripturl
         end
     total += open(scripturl).length
   end
   ensure
   return total
   end
 end
 

end