class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  require 'gdata'

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
  
  def show
    @user = current_user
  end

    def info
    end
    def about
    end
    def data
    end

    # Connect the user account with a Google Analytics account
    def connect
      if session[:token]
        reset_session 
      end
      scope = 'https://www.google.com/analytics/feeds/'
      next_url = 'http://localhost:3000/welcome'
      #next_url = 'http://greenalytics.org/sites/select'
      secure = false  # set secure = true for signed AuthSub requests
      sess = true
      @authsub_link = GData::Auth::AuthSub.get_url(next_url, scope, secure, sess)
    end

    def welcome
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
       current_user.gtoken = session[:token]
       current_user.save
       
       @feed = client.get('https://www.google.com/analytics/feeds/accounts/default').to_xml
       @feed.elements.each('entry') do |entry|    
          newsite = current_user.sites.new
          newsite.gid = entry.elements["dxp:tableId"].text
          newsite.name = entry.elements["title"].text
          newsite.user_id = current_user.id
          newsite.save
        end       
    end


  end


