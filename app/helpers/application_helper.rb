# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def monthname(monthnumber)  
      if monthnumber  
          Date::MONTHNAMES[monthnumber]  
       end  
 end
 
  def formatco2(co2)
      co2 = co2.to_f
      if co2 > 1000000  
          return "<co2> " + ((co2/1000000).round(1)).to_s + "</co2> tons CO<sub>2</sub>"  
       end  
       if co2 > 1000  
          return "<co2> " + ((co2/1000).round(1)).to_s + "</co2> kg CO<sub>2</sub>"  
       else 
         return "<co2> " + co2.to_s + "</co2> grams CO<sub>2</sub>" 
       end
 end
 
 def formattime(mins)
   mins = mins.to_i
   if mins > 60
     return ((mins/60).round).to_s + " hours"
   else
     return mins.to_s + " minutes"
   end
 end
 
end
