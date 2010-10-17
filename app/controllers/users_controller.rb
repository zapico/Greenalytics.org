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
       redirect_to :controller => "sites", :action => "select" 
    end
    
    # REMOVE GOOGLE ANALYTICS
    def downgrade
      current_user.gtoken = nil
      puts current_user.gtoken
      current_user.save
      redirect_to :action => "show"
    end


end


