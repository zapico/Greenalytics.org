# GREENALYTICS
# Sites controller
# Contains the functions for showing the information for sites
# Created by Jorge L. Zapico // jorge@zapi.co // http://jorgezapico.com
# Created for the Center for Sustainable Communications More info at http://cesc.kth.se
# 2010
# Open Source License

class SitesController < ApplicationController
 require 'rubygems'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gdata'
 before_filter :authorize, :except => [:show,:show_month,:show_next_month, :public]
 before_filter :authorize_admin, :only => [:allsites, :add_average_size, :change_address]
 
 
 # PUBLIC FUNCTION FOR SHOWING THE YEAR
 def show
   begin
     @site = Site.find(params[:id])
     if @site.ispublic then
     
     @emissions =  @site.emissions.find(:all, :limit => 12)
     # INITIALIZE
     @total_co2 = 0
     @server_co2 = 0
     @users_co2 = 0
     @visitors = 0
     
   # Create the month navigation
   @year = DateTime.now.year
   @month = DateTime.now.month
   @thismonth = @site.emissions.find(:first, :conditions => {:month => @month.to_s, :year => @year})
   if @month == 12
   	@nextmonth = @site.emissions.find(:first, :conditions => {:month => (1).to_s, :year => (@year+1).to_s})
   else
	@nextmonth = @site.emissions.find(:first, :conditions => {:month => (@month+1).to_s, :year => @year.to_s})
   end
   if @month == 1
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => (12).to_s, :year => (@year-1).to_s})
   else
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => (@month-1).to_s, :year => @year.to_s})
   end
     @id = @thismonth.id

     # AGGREGATE
     @emissions.each do |e| 
       @total_co2 += e.co2_server + e.co2_users
       @server_co2 += e.co2_server
       @users_co2 += e.co2_users
       @visitors += e.visitors.to_i
     end   
     # CREATE PIE GRAPHIC
     per_visitors =  @users_co2/@total_co2
     per_server = @server_co2/@total_co2
     @grafico="http://chart.apis.google.com/chart?chs=250x100&amp;chd=t:"+per_visitors.to_s+","+per_server.to_s+"&amp;cht=p3&amp;chl=Visitors|Server"

     # TRANSLATE USING CARBON.TO
     flight = Net::HTTP.get(URI.parse("http://carbon.to/flight.json?co2="+ (@total_co2/1000).round.to_s))
     flight = ActiveSupport::JSON.decode(flight)
     @flightamount = flight["conversion"]["amount"]
     car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ (@total_co2/1000).round.to_s))
     car = ActiveSupport::JSON.decode(car)
     @caramount = car["conversion"]["amount"]

     # CALCULATE GRAM PER VISITOR
     @grampervisitor = 0.00
     if @visitors.to_i != 0
       @grampervisitor = @total_co2.to_f / @visitors.to_i
     end
   else
   render :nothing => true
   end
   #Rescue error
     rescue Exception => exc
       render :action => "error"
     end
     
 end
 
 # SHOW ALL THE PUBLIC SITES
 def public
   # Cache for 12 hours
   
   
   @month = 0
   @total = 0
   @sites = Site.find(:all, :conditions => ["ispublic = true"])
   Site.find(:all).each do |si|
     si.emissions.each do |em|
       if em.month == DateTime.now.month
         @month += em.co2_users.to_i  + em.co2_server.to_i
       end
      @total += em.co2_users.to_i + em.co2_server.to_i
    end
   end
   begin
     car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ (@total/1000).round.to_s))
     car = ActiveSupport::JSON.decode(car)
     @caramount = car["conversion"]["amount"]
    rescue
     @caramount = 0 
   end
   
 end
 
 # SHOW THE AGGREGATES FOR A YEAR
 def show_year
   begin
   @site = Site.find(params[:id])  
   # Take the last emissions
   @emissions =  @site.emissions.find(:all, :limit => 12)
   
   # INITIALIZE
   @total_co2 = 0
   @server_co2 = 0
   @users_co2 = 0
   @visitors = 0
   
   # Create the month navigation
   @year = DateTime.now.year
   @month = DateTime.now.month
   @thismonth = @site.emissions.find(:first, :conditions => {:month => @month.to_s, :year => @year})
   if @month == 12
   	@nextmonth = @site.emissions.find(:first, :conditions => {:month => '1', :year => (@year+1).to_s})
   else
	@nextmonth = @site.emissions.find(:first, :conditions => {:month => (@month+1).to_s, :year => @year.to_s})
   end
   if @month == 1
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => '12', :year => (@year-1).to_s})
   else
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => (@month-1).to_s, :year => @year.to_s})
   end
   @id = @thismonth.id

   # AGGREGATE
   @emissions.each do |e| 
     @total_co2 += e.co2_server + e.co2_users
     @server_co2 += e.co2_server
     @users_co2 += e.co2_users
     @visitors += e.visitors.to_i
   end   
   # CREATE PIE GRAPHIC
   per_visitors =  @users_co2/@total_co2
   per_server = @server_co2/@total_co2
   @grafico="http://chart.apis.google.com/chart?chs=250x100&amp;chd=t:"+per_visitors.to_s+","+per_server.to_s+"&amp;cht=p3&amp;chl=Visitors|Server"

   # TRANSLATE USING CARBON.TO
   flight = Net::HTTP.get(URI.parse("http://carbon.to/flight.json?co2="+ (@total_co2/1000).round.to_s))
   flight = ActiveSupport::JSON.decode(flight)
   @flightamount = flight["conversion"]["amount"]
   car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ (@total_co2/1000).round.to_s))
   car = ActiveSupport::JSON.decode(car)
   @caramount = car["conversion"]["amount"]
   
   # CALCULATE GRAM PER VISITOR
   @grampervisitor = 0.00
   if @visitors.to_i != 0
     @grampervisitor = @total_co2.to_f / @visitors.to_i
   end
   
   respond_to do |format|
     format.html # show.html.erb
     format.xml  { render :xml => @countries }
   end
   rescue Exception => exc
     render :action => "error"
   end 
   
 end
 
 # SHOW PREVIOUS MONTH WHEN IN YEAR VIEW
 def show_month
   e = Emission.find(params[:id])
   @id = params[:id]
   @site = Site.find(e.site.id)
   @year = e.year.to_i
   @month = e.month.to_i - 1
   if e.month == 1
     @year -= 1     
     @month = 12
   end
   
   @thismonth = @site.emissions.find(:first, :conditions => {:month => @month.to_s, :year => @year.to_s})
   if @month == 12
   	@nextmonth = @site.emissions.find(:first, :conditions => {:month => (1).to_s, :year => (@year+1).to_s})
   else
	@nextmonth = @site.emissions.find(:first, :conditions => {:month => (@month+1).to_s, :year => @year.to_s})
   end
   if @month == 1
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => (12).to_s, :year => (@year-1).to_s})
   else
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => (@month-1).to_s, :year => @year.to_s})
   end
   @id = @thismonth.id
   render :partial => 'month'
 end
 
 # SHOW NEXT MONTH WHEN IN YEAR VIEW
 def show_next_month
   e = Emission.find(params[:id])
   @id = params[:id]
   @site = Site.find(e.site.id)
   @year = e.year.to_i
   @month = e.month.to_i + 1
   if e.month == 12
     @year += 1
     @month = 1     
   end
   
   @thismonth = @site.emissions.find(:first, :conditions => {:month => @month.to_s, :year => @year.to_s})
   if @month == 12
   	@nextmonth = @site.emissions.find(:first, :conditions => {:month => "1", :year => (@year+1).to_s})
   else
	@nextmonth = @site.emissions.find(:first, :conditions => {:month => (@month+1).to_s, :year => @year.to_s})
   end
   if @month == 1
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => "12", :year => (@year-1).to_s})
   else
   	@prevmonth = @site.emissions.find(:first, :conditions => {:month => (@month-1).to_s, :year => @year.to_s})
   end
   @id = @thismonth.id
   render :partial => 'month'
 end
 
 # CONNECT WITH GOOGLE ANALYTICS
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
 
 # CREATE A NEW SITE
 def new_site
   newsite = Site.new()
   newsite.gid = params[:gid]
   newsite.name = params[:name]
   newsite.user_id = current_user.id
   newsite.save
   get_address(newsite.id)
   calculate_first_time(newsite.id)
   redirect_to :action => "select"
 end
 
 # DELETE SITE
 def destroy
   @site = Site.find(params[:id])
   @site.destroy
   respond_to do |format|
     format.html { redirect_to :action => "select" }
     format.xml  { head :ok }
   end  
 end
 
 # ADMIN SITES
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
      redirect_to :controller => "users", :action => "show"
   end
 end
 
 # ADMIN ALL SITES
 def allsites
   @sites = Site.find(:all)
   @users = User.find(:all)
 end 
 
 # SHOW ALL SITES FOR THE LOGGED USER
 def my_sites
   user = current_user
   @month = 0
   @total = 0
   user.sites.each do |si|
     si.emissions.each do |em|
       if em.month == DateTime.now.month
         @month += em.co2_users.to_i  + em.co2_server.to_i
       end
      @total += em.co2_users.to_i + em.co2_server.to_i
    end
   end
   begin
     car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ (@total/1000).round.to_s))
     car = ActiveSupport::JSON.decode(car)
     @caramount = car["conversion"]["amount"]
    rescue
     @caramount = 0 
   end
 end
 
# GET THE ADDRESS
 def get_address (siteid)
   # Create a client and login using session   
   client = GData::Client::GBase.new
   site = Site.find(siteid)
   client.authsub_token = site.user.gtoken
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
   render :nothing => true
 end
 
 def get_address_admin
   # Create a client and login using session   
   client = GData::Client::GBase.new
   site = Site.find(params[:site_id])
   client.authsub_token = site.user.gtoken
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
   render :nothing => true
 end
 
 
 # TRIGGERS CALCULATION FOR A WHOLE YEAR
 def calculate_past
   site_id = params[:id]
   year = DateTime.now.year
   month = DateTime.now.month
   x = 0
   while x < 2
     month -= 1
     if month == 0 then 
       year -= 1
       month = 12
     end
     x = x+1
     puts "Calculating"
     puts site_id
     date_start = Date.new(year, month, 1)
     d = date_start
     d += 42
     date_end =  Date.new(d.year, d.month) - 1
     puts date_end.to_s
     puts date_start.to_s
     system " RAILS_ENV=#{RAILS_ENV} ruby #{RAILS_ROOT}/script/runner 'calculate_site.new(site_id,date_start,date_end)' & "
   end
   render :nothing => true
 end
 
 # MANUAL WAY OF ADDING URL ADDRESS
 def change_address
   site = Site.find(params[:id])
   site.address = params[:url]
   site.save
   render :nothing => true
 end
 
 # MANUAL WAY OF ADDING AVERAGE SIZE IN CASE CALCULATIONS FAIL
 def add_average_size
   site = Site.find(params[:id])
   site.avgsize = params[:size].to_i
   site.save
   render :nothing => true
 end
  
 # IT CHANGES THE STATUS BETWEEN PUBLIC AND NOT PUBLIC 
 def makepublic
   site = Site.find(params[:id])
   if site.ispublic == true
     site.ispublic = false
   else
     site.ispublic = true
   end
   site.save
   redirect_to :action => "select"
 end
 
 # TRIGGERS CALCULATION FOR THE CURRENT MONTH
 def calculate_this_month
     site_id = params[:id]
     date_end = DateTime.now
     nrday = date_end.day.to_i
     nrday -= 1
     date_start = DateTime.now-nrday.days
     Delayed::Job.enqueue CalculateSite.new(site_id,date_start,date_end)
     #calculate_month(site_id,date_start,date_end)
     render :nothing => true
   end
  
   def calculate_first_time(site_id)
     year = DateTime.now.year
     month = DateTime.now.month
     while year > 2009
       date_start = Date.new(year, month, 1)
       d = date_start
       d += 42
       date_end =  Date.new(d.year, d.month) - 1
       Delayed::Job.enqueue CalculateSite.new(site_id,date_start,date_end)
       month -= 1
       if month == 0 then 
         year -= 1
         month == 12
       end
     end
     render :nothing => true
   end
   
   def calculate_older_all
     Site.find(:all).each do |site|
       date_start = Date.new(2010, 1, 1)
       date_end =  Date.new(2010, 1, 31)
       Delayed::Job.enqueue CalculateSite.new(site.id,date_start,date_end)
       date_start = Date.new(2009, 12, 1)
       date_end =  Date.new(2009, 12, 31)
       Delayed::Job.enqueue CalculateSite.new(site.id,date_start,date_end)
     end
   end
  
  # ERROR
  def error
  end
  
  # MAIN FUNCTION THAT CALCULATES FOR A GIVEN MONTH AND A GIVEN SITE
  def calculate_site(site_id,date_start,date_end)
    site = Site.find(site_id)
    # A. LOGIN AND ALL THAT
     # 1. Create a client and login using the stored information   
      site = Site.find(site_id)
      client = GData::Client::GBase.new
      client.authsub_token = site.user.gtoken
      profile_id = site.gid
      
      # 2. Create a new emission
      
      if site.emissions.find(:first, :conditions => { :year => date_start.year(), :month => date_start.month() })
        emission = site.emissions.find(:first, :conditions => { :year => date_start.year(), :month => date_start.month() })
        puts "Overwrote emission"
      else
        emission = site.emissions.new
        puts "Created a new emission"
      end
        
      emission.year = date_start.year()
      emission.month = date_start.month()
      day_start = date_start.strftime("%Y-%m-%d")
      day_end =  date_end.strftime("%Y-%m-%d")
      
      # B. CALCULATE TOTAL TRAFFIC
      # 1. Get the pageview of all apges
      allpages = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:pagePath&metrics=ga:pageviews&sort=-ga:pageviews&start-date='+day_start+'&end-date='+day_end).to_xml

      # 2. Initialiate variables
      total_size = 0
      totalvisits = 0
      page_text = ""
      if site.address then
        address = site.address
      else
        # Create a client and login using session   
        client = GData::Client::GBase.new
        client.authsub_token = site.user.gtoken
        site = Site.find(site_id)
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
      end
      
      # 3. Iterate through the different pages
      pagecounter = 0
      averagesize = 0
      allpages.elements.each('entry') do |point|
        # 3.1 Get the URL
        url = point.elements["dxp:dimension name='ga:pagePath'"].attribute("value").value
        # 2. Get the number of visitors
        visits = point.elements["dxp:metric name='ga:pageviews'"].attribute("value").value
        # 3. Aggregate text
        if visits.to_i > 1 then
            if pagecounter < 20
              pagesize = pageSize(address+url)/1024
              # Calculate average size of the pages
              averagesize += pagesize
              pagecounter += 1
            else
              # After 20 times use the average size to not overload 
              pagesize = averagesize/20
            end
            if pagesize == 0 and site.avgsize != nil then
              pagesize = site.avgsize
            end
            total_size += pagesize*visits.to_i
        end
        totalvisits += visits.to_i
       end
       emission.traffic = total_size

      # C. CALCULATE SERVER
      #  1. Get the country where the server is located
      address = site.address.to_s.split("//")[1]
      country = ""
      #  1.1 Grab the info from API
      uri = "http://api.ipinfodb.com/v2/ip_query_country.php?key=f03ff18218a050bb05f6b501ce49c10a4f6f063eef9151109de17e299b3b0835&ip=#{address}"
      #  1.2 Get the name using Hpricot
      doc = Hpricot(open(uri))
      (doc/'response').each do |el|
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
      emission.factor = 3.5
      # 3.2 Calculate CO2
      co2_server = 0
      co2_server = total_size * emission.factor * serverfactorgr # kB * (kWh/Gb) * kg 
      co2_server = co2_server /  1025 #Adjusting for kB to Gb and Kg to grams
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
             factor = "501"
          end
        end
        #Save in our database
        c = Country.new()
        c.name = name
        c.factor = factor
        c.save
      end
      
      if factor == "" then
         factor = "501"
       end
       # Parse time  
       time2 = land.elements["dxp:metric name=ga:'timeOnSite'"].attribute("value").value
       time2 = (time2.to_f/60).round(2)
       # Calculate the impact
       carbonimpact = factor.to_f * time2 * 35.55 / 60000
       # Aggregate
       co2_visitors += carbonimpact
       time += time2
       grams = carbonimpact.round(2)
       if grams != 0
         text = "<b>" + name.to_s + "</b> " + time2.to_s + " min "+ grams.to_s + " grams CO2. With a factor of "+factor.to_f.round(2).to_s+"<br/>"
         visitors_text += text
       end  
    end
    #Save in database
    emission.co2_users = co2_visitors
    emission.text_users = visitors_text     
    emission.visitors = totalvisits.to_i
    emission.time = time.to_d
    
    # AND SAVE
    emission.save
  end 
 
  # GIVES BACK THE PAGE SIZE OF AN URL
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
