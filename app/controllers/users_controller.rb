# GREENALYTICS
# Users controller
# Created by Jorge L. Zapico // jorge@zapi.co // http://jorgezapico.com
# Created for the Center for Sustainable Communications More info at http://cesc.kth.se
# 2010
# Open Source License


class UsersController < ApplicationController
  require 'gdata'
  before_filter :authorize, :only => [:show, :downgrade]

  # Create new user
  def new
    @user = User.new
  end
  
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end
  
  # Show current user (My account)
  def show
    @user = current_user
  end
  
  # STATIC PAGES (INFO, ABOUT, EXAMPLE, DATA)
  def info
  end
  def about
  end
  def example
  end
  def data
  end
  def donate
  end

  # Connect the user account with a Google Analytics account
  def connect
      scope = 'https://www.google.com/analytics/feeds/'
      #next_url = 'http://localhost:3000/welcome'
      next_url = 'http://greenalytics.heroku.com/welcome'
      secure = false  # set secure = true for signed AuthSub requests
      sess = true
      @authsub_link = GData::Auth::AuthSub.get_url(next_url, scope, secure, sess)
  end

  # UPGRADE THE TOKEN AND SAVE IT IN THE DATABASE
  def welcome      
      client = GData::Client::GBase.new
      # Get's the token
      if session[:token]
         client.authsub_token = session[:token]
      else
         if params[:token]
           client.authsub_token = params[:token] # extract the single-use token from the URL query params
           session[:token] = client.auth_handler.upgrade() # upgrade the token
           client.authsub_token = session[:token] if session[:token] 
         else
           redirect_to :action => "login"
         end
       end  
       current_user.gtoken = session[:token] # save the token to the current user
       current_user.save
       
       # Get all the sites of the user and add them to greenalyics
       @feed = client.get('https://www.google.com/analytics/feeds/accounts/default').to_xml
       @feed.elements.each('entry') do |entry|    
          newsite = current_user.sites.new
          newsite.gid = entry.elements["dxp:tableId"].text
          newsite.name = entry.elements["title"].text
          newsite.user_id = current_user.id
          get_address(newsite.id)
          calculate_first_time(newsite.id)
          newsite.save
        end       
    end
    
    def calculate_first_time(site_id)
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
        if month == 1 then 
          year -= 1 
        end
      end
    end
    
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
      puts address
    end
    
    # REMOVE GOOGLE ANALYTICS
    def downgrade
      current_user.gtoken = nil
      puts current_user.gtoken
      current_user.save
      redirect_to :action => "show"
    end


end


