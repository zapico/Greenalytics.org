class SitesController < ApplicationController
 require 'rubygems'
 require 'whois'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gdata'
 
 def show
   @site = Site.find(params[:id])

   respond_to do |format|
     format.html # show.html.erb
     format.xml  { render :xml => @countries }
   end
 end
 
 def login
   if session[:token]
     reset_session 
   end
   scope = 'https://www.google.com/analytics/feeds/'
   #next_url = 'http://localhost:3000/sites/select'
   next_url = 'http://greenalytics.heroku.com/sites/select'
   secure = false  # set secure = true for signed AuthSub requests
   sess = true
   @authsub_link = GData::Auth::AuthSub.get_url(next_url, scope, secure, sess)
 end
 
 def select
   begin
   client = GData::Client::GBase.new
   # Grab the token from the db
   client.authsub_token = current_user.gtoken
   # Get the list with the site
   @feed = client.get('https://www.google.com/analytics/feeds/accounts/default').to_xml
   rescue Exception => exc
      logger.error("Message for the log file #{exc.message}")
      flash[:notice] = "No google analytics connected to this account"
      redirect_to :controller => "sessions", :action => "new"
   end
   
 end
 

 # GET THE ADDRESS
 def get_address(siteid)
   # Create a client and login using session   
   client = GData::Client::GBase.new
   client.authsub_token = current_user.gtoken
   site = Site.find(siteid)
   today= DateTime.now-1.days
   amonthago = today-30.days
   today = today.strftime("%Y-%m-%d")
   amonthago = amonthago.strftime("%Y-%m-%d")
   # Get address (Not as easy as it should be!)
   address = client.get('https://www.google.com/analytics/feeds/data?ids='+site.gid+'&dimensions=ga:hostname&metrics=ga:pageviews&start-date='+amonthago+'&end-date='+today+'&sort=-ga:pageviews&aggregates=ga:hostname').to_xml
   address = address.to_s.split("dxp:dimension name='ga:hostname' value='")[1]
   address = address.to_s.split("'")[0]
   address = "http://"+address.to_s   
   # Save the address in the db
   site.address = address
   site.save
   puts address
 end
 
 def calculate
    
     # Create a client and login using session   
     client = GData::Client::GBase.new
     client.authsub_token = current_user.gtoken
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
     # Create a client and login using session   
     client = GData::Client::GBase.new
     client.authsub_token = current_user.gtoken
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
     
     # GET COUNTRY WHERE THE SERVER IS LOCATED
     address = params[:address].to_s.split("//")[1]
     country = ""
     # Grab the info from API
     uri = "http://ipinfodb.com/ip_query2.php?ip=#{address}"
     # Get the name using Hpricot
     doc = Hpricot(open(uri))
     (doc/'location').each do |el|
       country = (el/'countryname').inner_html.to_s
     end
     
     # GET THE EMISSION OF THAT COUNTRY
     if Country.find(:first,:conditions => [ "name = ?", country ]) then
         serverfactor=Country.find(:first,:conditions => [ "name = ?", country ]).factor
         serverfactorgr = serverfactor/1000
       else
         serverfactorgr=0.501
     end
     
     @server_text = "<p> The server is located in <b>" + country + "</b> where the carbon factor is " + serverfactor.to_s + " gram CO2 per kW/h"
     
     # CALCULATE SERVER AND INFRA IMPACT
     @co2_server = 0
     @co2_server = @total_size * 9 * serverfactorgr
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
    

   render :update do |page|
      page.hide "search-indicator"
      page.hide "text"
      page.replace_html 'calculate', :partial => 'calculate'
    end
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
 
 def calculate_this_month
   site_id = params[:id]
   date_end = DateTime.now
   nrday = date_end.day.to_i
   nrday -= 1
   date_start = DateTime.now-nrday.days
   calculate_month(site_id,date_start,date_end)
   render :nothing => true
 end

 def destroy_emissions
   site = Site.find(params[:id])
   site.emissions.each do |em|
     em.destroy
   end
 end
 
 # SAVE ALL THE INFORMATION FOR THE EMISSIONS OF A MONTH
  def calculate_month (site_id,date_start,date_end)       
       
       # A. LOGIN AND ALL THAT
       # 1. Create a client and login using the stored information   
        site = Site.find(site_id)
        client = GData::Client::GBase.new
        client.authsub_token = site.user.gtoken
        profile_id = site.gid
        
        # 2. Create a new emission
        emission = site.emissions.new
        emission.date_start = date_start
        emission.date_end = date_end
        day_start = emission.date_start.strftime("%Y-%m-%d")
        day_end =  emission.date_start.strftime("%Y-%m-%d")

        # B. CALCULATE TOTAL TRAFFIC
        # 1. Get the pageview of all apges
        allpages = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:pagePath&metrics=ga:pageviews&start-date='+day_start+'&end-date='+day_end).to_xml
        # 2. Initialiate variables
        total_size = 0
        totalvisits = 0
        page_text = ""
        if site.address then
          address = site.address
        else
          address = get_adress(site.id)
        end
        # 3. Iterate through the different pages
        
        allpages.elements.each('entry') do |point|
          # 3.1 Get the URL
          url = point.elements["dxp:dimension name='ga:pagePath'"].attribute("value").value
          # 2. Get the number of visitors
          visits = point.elements["dxp:metric name='ga:pageviews'"].attribute("value").value
          # 3. Aggregate text
          if visits.to_i > 1 then
            pagesize = pageSize(address+url)/1024
            totalvisits += visits.to_i
            total_size += pagesize*visits.to_i
          end
         end
         emission.traffic = total_size

        # C. CALCULATE SERVER
        #  1. Get the country where the server is located
        address = params[:address].to_s.split("//")[1]
        country = ""
        #  1.1 Grab the info from API
        uri = "http://ipinfodb.com/ip_query2.php?ip=#{address}"
        #  1.2 Get the name using Hpricot
        doc = Hpricot(open(uri))
        (doc/'location').each do |el|
          country = (el/'countryname').inner_html.to_s
        end
        # 2. Get the emission factor for that country
        if Country.find(:first,:conditions => [ "name = ?", country ]) then
            serverfactor=Country.find(:first,:conditions => [ "name = ?", country ]).factor
            serverfactorgr = serverfactor/1000
          else
            serverfactorgr=0.501
        end
        emission.server_location = country
        # 3. Calculate the CO2
        # 3.1 Set the factor kWh per GB
        emission.factor = 9
        # 3.2 Calculate CO2
        co2_server = 0
        co2_server = total_size * emission.factor * serverfactorgr
        co2_server = co2_server /  1048576
        # 3.3 Save in the db
        emission.co2_server = co2_server
        
      # D. CALCULATE VISITORS IMPACT
      # Get the visitor information from Google Analytics
      visitors = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:country&metrics=ga:timeOnSite&start-date='+day_start+'&end-date='+day_end+'&aggregates=ga:country').to_xml
      # Parse the time on site by country 
      visitors_text = " "
      time = 0 
      co2_visitors = 0
      totalvisitors = 0
      visitors.elements.each('entry') do |land|
      # Parse country
      name = land.elements["dxp:dimension name='ga:country'"].attribute("value").value
      # Get carbon factor
      factor = ""
      # See if it exists in our database
      if Country.find(:first,:conditions => [ "name = ?", name ]) then
           factor=Country.find(:first,:conditions => [ "name = ?", name ]).factor
       else
         # If do not exist then we create it in database and retrieve info from CARMA
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
         time2 = land.elements["dxp:metric name=ga:'timeOnSite'"].attribute("value").value
         time += time2.to_i
         # Calculate the impact
         carbonimpact = factor.to_f * time.to_i * 35.55 / 3600000
         co2_visitors += carbonimpact
         # Aggregate
         time = (time.to_f/60).round(1)
         grams = carbonimpact.round(2)
         if grams != 0
           text = "<b>" + name.to_s + "</b> " + time.to_s + " min "+ grams.to_s + " grams CO2. With a factor of "+factor.to_f.round(2).to_s+"<br/>"
           visitors_text += text
         end  
      co2_visitors = co2_visitors/1000
      time = time/60    
      #Save in database
      emission.co2_users = co2_visitors
      emission.text_users = visitors_text     
      emission.visitors = totalvisits.to_i
      emission.time = time
      
      # AND SAVE
      emission.save
    end
  end
end