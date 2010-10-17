# GREENALYTICS
# Sites controller
# Contains the main functionality of the site
# Created by Jorge L. Zapico // jorge@zapi.co // http://jorgezapico.com
# Created for the Center for Sustainable Communications More info at http://cesc.kth.se
# 2010
# Open Source License

class SitesController < ApplicationController
 require 'rubygems'
 require 'whois'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gdata'
 before_filter :authorize
 before_filter :authorize_admin, :only => [:allsites]
 
 
 # IT SHOWS THE EMISSIONS FOR A SITE FOR A GIVE MONTH PARAMS: ?id=,year=,month=
 def show
   begin
   @site = Site.find(params[:id])
   if params[:year] & params[:month]
     @emission =  @site.emissions.find(:first, :conditions => { :year => params[:year], :month => params[:month]})
    else
      @emission =  @site.emissions.find(:first, :conditions => { :year => DateTime.now.year.to_s, :month => DateTime.now.month.to_s})
   end
   
   # CREATE PIE GRAPHIC
   @total_co2 = @emission.co2_server + @emission.co2_users
   per_visitors = @emission.co2_users*100/@total_co2
   per_server = @emission.co2_server*100/@total_co2
   @grafico="http://chart.apis.google.com/chart?chs=250x100&amp;chd=t:"+per_visitors.to_s+","+per_server.to_s+"&amp;cht=p3&amp;chl=Visitors|Server"

   # TRANSLATE USING CARBON.TO
   light = Net::HTTP.get(URI.parse("http://carbon.to/lightbulb.json?co2="+ (@total_co2/1000).round.to_s))
   light = ActiveSupport::JSON.decode(light)
   @lightamount = light["conversion"]["amount"]
   car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ (@total_co2/1000).round.to_s))
   car = ActiveSupport::JSON.decode(car)
   @caramount = car["conversion"]["amount"]

   
   # CALCULATE GRAM PER VISITOR
   @grampervisitor = 0.00
   if @emission.visitors.to_i != 0
     @grampervisitor = @total_co2.to_f / @emission.visitors.to_i

   end
   
   respond_to do |format|
     format.html # show.html.erb
     format.xml  { render :xml => @countries }
   end
   
   # Rescue error
   rescue Exception => exc
     render :action => "error"
   end
   
   
 end
 
 # SHOW THE AGGREGATES FOR A YEAR
 def show_year
   begin
   @site = Site.find(params[:id])
   if params[:year]
     @emissions =  @site.emissions.find(:all, :conditions => { :year => params[:year]})
     @year = params[:year]
    else
       @emissions =  @site.emissions.find(:all, :conditions => { :year => DateTime.now.year.to_s})
       @year = DateTime.now.year.to_s
   end
   # INITIALIZE
   @total_co2 = 0
   @server_co2 = 0
   @users_co2 = 0
   @visitors = 0
   
   # AGGREGATE
   @emissions.each do |e| 
     @total_co2 += e.co2_server + e.co2_users
     @server_co2 += e.co2_server
     @users_co2 += e.co2_users
     @visitors += e.visitors.to_i
   end
   # CHANGE TO KG
   @total_co2 /= 1000
   @server_co2 /= 1000
   @users_co2 /= 1000
   
   # CREATE PIE GRAPHIC
   per_visitors =  @users_co2*100/@total_co2
   per_server = @server_co2*100/@total_co2
   @grafico="http://chart.apis.google.com/chart?chs=250x100&amp;chd=t:"+per_visitors.to_s+","+per_server.to_s+"&amp;cht=p3&amp;chl=Visitors|Server"

   # TRANSLATE USING CARBON.TO
   beer = Net::HTTP.get(URI.parse("http://carbon.to/beers.json?co2="+ @total_co2.round.to_s))
   beer = ActiveSupport::JSON.decode(beer)
   @beeramount = beer["conversion"]["amount"]
   car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ @total_co2.round.to_s))
   car = ActiveSupport::JSON.decode(car)
   @caramount = car["conversion"]["amount"]
   
   # CALCULATE GRAM PER VISITOR
   @grampervisitor = 0.00
   if @visitors.to_i != 0
     @grampervisitor = @total_co2.to_f / @visitors.to_i
     @grampervisitor = @grampervisitor*1000
   end
   
   respond_to do |format|
     format.html # show.html.erb
     format.xml  { render :xml => @countries }
   end
   # Rescue error
   rescue Exception => exc
     render :action => "error"
   end
   
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
 
 # SHOW ALL SITES
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
 
 # TRIGGERS CALCULATION FOR A WHOLE YEAR
 def calculate_past
   site_id = params[:id]
   year = DateTime.now.year
   month = DateTime.now.month
   while year == 2010
     date_start = Date.new(year, month, 1)
     d = date_start
     d += 42
     date_end =  Date.new(d.year, d.month) - 1
     puts date_end.to_s
     puts date_start.to_s
     Delayed::Job.enqueue CalculateSite.new(site_id,date_start,date_end)
     month -= 1
     if month == 1 then year -= 1 end
   end
   render :nothing => true
 end
 
 # TRIGGERS CALCULATION FOR THE CURRENT MONTH
 def calculate_this_month

  # UPDATE ALL THE SITES, RUN AS CRONJOB
  def daily_update
    sites = Site.find(:all)
    date_end = DateTime.now
    nrday = date_end.day.to_i
    nrday -= 1
    date_start = DateTime.now-nrday.days
    sites.each do |si|  
      calculate_month(si.id,date_start,date_end)
    end
  end

  # ERROR
  def error
  end

end