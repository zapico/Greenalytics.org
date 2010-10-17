class CalculateSite
  require 'rubygems'
  require 'whois'
  require 'garb'
  require 'hpricot'
  require 'open-uri'
  require 'gdata' 
  attr_accessor :site_id
  attr_accessor :date_start
  attr_accessor :date_end
  
  def initialize(site_id,date_start,date_end)
    self.site_id = site_id
    self.date_start = date_start
    self.date_end = date_end
  end
  
  def perform
    site = Site.find(site_id)
    # A. LOGIN AND ALL THAT
     # 1. Create a client and login using the stored information   
      site = Site.find(site_id)
      client = GData::Client::GBase.new
      client.authsub_token = site.user.gtoken
      profile_id = site.gid
      
      # 2. Create a new emission
      
      if site.emissions.find(:first, :conditions => { :year => date_start.year(), :month => date_start.month() })
        emission = site.emissions.find(:first, :conditions => { :year => date_start.year(), :month => date_start.month() })
        puts "Overwrote emission"
      else
        emission = site.emissions.new
        puts "Created a new emission"
      end
        
      emission.year = date_start.year()
      emission.month = date_start.month()
      day_start = date_start.strftime("%Y-%m-%d")
      day_end =  date_end.strftime("%Y-%m-%d")
      
      # B. CALCULATE TOTAL TRAFFIC
      # 1. Get the pageview of all apges
      allpages = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:pagePath&metrics=ga:pageviews&start-date='+day_start+'&end-date='+day_end).to_xml
      # 2. Initialiate variables
      total_size = 0
      totalvisits = 0
      page_text = ""
      if site.address then
        address = site.address
      else
        # Create a client and login using session   
        client = GData::Client::GBase.new
        client.authsub_token = site.user.gtoken
        site = Site.find(site_id)
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
      end
      # 3. Iterate through the different pages
      
      allpages.elements.each('entry') do |point|
        # 3.1 Get the URL
        url = point.elements["dxp:dimension name='ga:pagePath'"].attribute("value").value
        # 2. Get the number of visitors
        visits = point.elements["dxp:metric name='ga:pageviews'"].attribute("value").value
        # 3. Aggregate text
        if visits.to_i > 1 then
          pagesize = pageSize(address+url)/1024
          totalvisits += visits.to_i
          total_size += pagesize*visits.to_i
        end
       end
       emission.traffic = total_size

      # C. CALCULATE SERVER
      #  1. Get the country where the server is located
      address = site.address.to_s.split("//")[1]
      country = ""
      #  1.1 Grab the info from API
      uri = "http://ipinfodb.com/ip_query2.php?ip=#{address}"
      #  1.2 Get the name using Hpricot
      doc = Hpricot(open(uri))
      (doc/'location').each do |el|
        country = (el/'countryname').inner_html.to_s
      end
      # 2. Get the emission factor for that country
      if Country.find(:first,:conditions => [ "name = ?", country ]) then
          serverfactor=Country.find(:first,:conditions => [ "name = ?", country ]).factor
          serverfactorgr = serverfactor/1000
        else
          serverfactorgr=0.501
      end
      emission.server_location = country
      # 3. Calculate the CO2
      # 3.1 Set the factor kWh per GB
      emission.factor = 9
      # 3.2 Calculate CO2
      co2_server = 0
      co2_server = total_size * emission.factor * serverfactorgr # kB * (kWh/Gb) * kg 
      co2_server = co2_server /  1025 #Adjusting for kB to Gb and Kg to grams
      # 3.3 Save in the db
      emission.co2_server = co2_server
      
    # D. CALCULATE VISITORS IMPACT
    # Get the visitor information from Google Analytics
    visitors = client.get('https://www.google.com/analytics/feeds/data?ids='+profile_id+'&dimensions=ga:country&metrics=ga:timeOnSite&start-date='+day_start+'&end-date='+day_end+'&aggregates=ga:country').to_xml
    # Parse the time on site by country 
    visitors_text = " "
    time = 0 
    co2_visitors = 0
    totalvisitors = 0
    visitors.elements.each('entry') do |land|
      # Parse country
      name = land.elements["dxp:dimension name='ga:country'"].attribute("value").value
      # Get carbon factor
      factor = ""
      # See if it exists in our database
      if Country.find(:first,:conditions => [ "name = ?", name ]) then
         factor=Country.find(:first,:conditions => [ "name = ?", name ]).factor
       else
       # If do not exist then we create it in database and retrieve info from CARMA
       if name then
         h_name = name.gsub(" ", "%20")
         begin
           carma = Net::HTTP.get(URI.parse("http://carma.org/api/1.1/searchLocations?region_type=2&name="+h_name+"&format=json"))
           # Parse the factor from Json string
           factor = carma.to_s.split("intensity")[1]
           factor = factor.to_s.split('present" : "')[1] 
           factor = factor.to_s.split('",')[0]
           rescue Exception => exc
             factor = "0.501"
          end
        end
        #Save in our database
        c = Country.new()
        c.name = name
        c.factor = factor
        c.save
      end
      
      if factor == "" then
         factor = "0.501"
       end
       # Parse time  
       time2 = land.elements["dxp:metric name=ga:'timeOnSite'"].attribute("value").value
       time2 = (time2.to_f/60).round(2)
       # Calculate the impact
       carbonimpact = factor.to_f * time2 * 35.55 / 60
       # Aggregate
       co2_visitors += carbonimpact
       time += time2
       grams = carbonimpact.round(2)
       if grams != 0
         text = "<b>" + name.to_s + "</b> " + time2.to_s + " min "+ grams.to_s + " grams CO2. With a factor of "+factor.to_f.round(2).to_s+"<br/>"
         visitors_text += text
       end  
    end
    #Save in database
    emission.co2_users = co2_visitors
    emission.text_users = visitors_text     
    emission.visitors = totalvisits.to_i
    emission.time = time.to_d
    puts emission.time
    puts time
    
    # AND SAVE
    emission.save
  end 
 
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
 
 end