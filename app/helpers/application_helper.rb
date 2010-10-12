# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def monthname(monthnumber)  
      if monthnumber  
          Date::MONTHNAMES[monthnumber]  
       end  
 end
end
