module SitesHelper
require 'hpricot'
require 'open-uri' 
  
  
  def pageSize (url)
     # Get HTML Size
    total = 0
    begin
    total = open(url).length
    
    hp = Hpricot(open(url))
    
    # Get images size
    hp.search("img").each do |p|
      picurl = url+p.attributes['src']
      total += open(picurl).length
    end
     # Get CSS size
     hp.search("link").each do |p|
      cssurl = url+p.attributes['href']
      total += open(cssurl).length
    end
    # Get script size
      hp.search("html/head//script").each do |p|
      scripturl = url+p.attributes['src']
      total += open(scripturl).length
    end
    ensure
    return total
    end
  end
  

  

end