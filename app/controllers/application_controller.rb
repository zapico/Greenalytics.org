# GREENALYTICS
# Application controller
# Created by Jorge L. Zapico // jorge@zapi.co // http://jorgezapico.com
# Created for the Center for Sustainable Communications More info at http://cesc.kth.se
# 2010
# Open Source License


# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  include AuthenticatedSystem
      
  def authorize  
     unless current_user
          flash[:notice] = "Please log in"
          redirect_to(:controller => "users", :action => "login")
     end
  end
  
  def authorize_admin
     unless current_user.login == "zapico"
          flash[:notice] = "Please log in"
          redirect_to(:controller => "users", :action => "login")
     end
  end
  
  
end
