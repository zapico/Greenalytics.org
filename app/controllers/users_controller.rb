# GREENALYTICS
# Users controller
# Created by Jorge L. Zapico // jorge@zapi.co // http://jorgezapico.com
# Created for the Center for Sustainable Communications More info at http://cesc.kth.se
# 2010
# Open Source License


class UsersController < ApplicationController
  require 'gdata'
  before_filter :authorize, :only => [:show, :downgrade]
  before_filter :authorize_admin, :only => [:delete]

  # Create new user
  def new
    @user = User.new
  end
  
  def delete
    @user = User.find(params[:id])
    @user.destroy
    redirect_back_or_default('/sites/allsites')
  end
  
  def create
    logout_keeping_session!
    if params[:user]["invitation"] == "greenmywebsite"
      @user = User.new(params[:user])
      success = @user && @user.save
      if success && @user.errors.empty?
      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/connect')  
      else
        flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
        redirect_back_or_default('/users/new')
      end
    else
      flash[:error]  = "You need an invitation, please contact us!"
      redirect_back_or_default('/users/new')
    end
  end
  
  # Show current user (My account)
  def show
    @user = current_user
  end
  
  # STATIC PAGES (INFO, ABOUT, EXAMPLE, DATA)
  def info
    response.headers['Cache-Control'] = 'public, max-age=3200'
    begin
       @site = Site.find(32)
       @emissions =  @site.emissions.find(:all, :conditions => { :year => DateTime.now.year.to_s})
       @year = DateTime.now.year.to_s
      
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
       # CREATE PIE GRAPHIC
       per_visitors =  @users_co2/@total_co2
       per_server = @server_co2/@total_co2
       @grafico="http://chart.apis.google.com/chart?chs=200x80&amp;chd=t:"+per_visitors.to_s+","+per_server.to_s+"&amp;cht=p3&amp;chl=Visitors|Server"

       # TRANSLATE USING CARBON.TO
       car = Net::HTTP.get(URI.parse("http://carbon.to/car.json?co2="+ (@total_co2/1000).round.to_s))
       car = ActiveSupport::JSON.decode(car)
       @caramount = car["conversion"]["amount"]
    end
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
      next_url = 'http://greenalytics.org/retrievetoken'
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
       redirect_to :controller => "sites", :action => "select" 
    end
    
    # REMOVE GOOGLE ANALYTICS
    def downgrade
      current_user.gtoken = nil
      current_user.save
      render :nothing => true
    end


end


