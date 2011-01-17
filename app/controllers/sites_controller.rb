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
   while year > 2009
     month -= 1
     if month == 0 then 
       year -= 1
       month = 12
     end
     puts "Calculating"
     puts year
     puts month
     date_start = Date.new(year, month, 1)
     d = date_start
     d += 42
     date_end =  Date.new(d.year, d.month) - 1
     puts date_end.to_s
     puts date_start.to_s
     Delayed::Job.enqueue CalculateSite.new(site_id,date_start,date_end)
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
  

end
