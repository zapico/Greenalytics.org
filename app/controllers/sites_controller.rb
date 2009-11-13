class SitesController < ApplicationController
 require 'rubygems'
 require 'rugalytics'
 require 'universal_ruby_whois' 
 require 'whois'
 require 'garb'
 require 'hpricot'
 require 'open-uri'
 require 'gattica'


 
 def test
    #Garb::Session.login('jorgezapico@gmail.com', 'rip2maQ1')
    #Garb::Account.all.first
    #@profile = Garb::Profile.all
    
    Rugalytics.login 'jorgezapico@gmail.com', 'rip2maQ1'
    @profile = Rugalytics.find_profile('Verde media','carbon.to')
    
     today= DateTime.now-1.days
     amonthago = today-30.days
     today = today.strftime("%Y-%m-%d")
     amonthago = amonthago.strftime("%Y-%m-%d")
     gs = Gattica.new({:email => 'jorgezapico@gmail.com', :password => 'rip2maQ1', :profile_id => 21441200})
     @results = gs.get({:start_date => amonthago, :end_date => today, :dimensions => 'pagePath', :metrics => 'pageviews'})
     
     @main_url = "http://carbon.to"
    
    # Get HTML Size
    @length = open(@main_url).length
    
    @hp = Hpricot(open(@main_url))
    
    @pictures_size = 0
    # Get images size
    @hp.search("img").each do |p|
      picurl = @main_url+p.attributes['src']
      @pictures_size += open(picurl).length
    end
     
     @scripts = 0
     # Get CSS size
     @hp.search("link").each do |p|
      cssurl = @main_url+p.attributes['href']
      @scripts += open(cssurl).length
    end
    # Get script size
    @hp.search("html/head//script").each do |p|
      scripturl = @main_url+p.attributes['src']
      @scripts += open(scripturl).length
    end
    

    
    @w = Whois::Client.new
    @w.query('70.32.99.240')

 
 end

end