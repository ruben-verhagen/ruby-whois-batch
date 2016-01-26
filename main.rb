require 'whois'
require 'csv'
require 'yaml'

def format_registrar(registrar)
  if registrar.nil?
    return ""
  else
    return "name:#{registrar.name}, organization:#{registrar.organization}, url:#{registrar.url}"
  end
end

def format_contacts(contacts)
  results = []
  contacts.each do |c|
    results.push "type:#{c.type}, name:#{c.name}, organization:#{c.organization}, address:#{c.address}, city:#{c.city}, zip:#{c.zip}, state:#{c.state}, country:#{c.country}, country_code:#{c.country_code}, phone:#{c.phone}, fax:#{c.fax}, email:#{c.email}, url:#{c.url}, created_on:#{c.created_on}, updated_on:#{c.updated_on}"
  end
  return results.join("|")
end

def format_name_servers(name_servers)
  results = []
  name_servers.each do |ns|
    results.push "name:#{ns.name}, ipv4:#{ns.ipv4}, ipv6:#{ns.ipv6}"
  end
  return results.join("|")
end

proxies = File.open('proxies').read
proxies_list = proxies.gsub!(/\r\n?/, "\n").split("\n")
puts "Loaded #{proxies_list.length} proxies"

input_filename = ARGV[0];
csv_file = ARGV[1];

CSV.open(csv_file, "wb") do |csv|
  csv << ["url", "status", "disclaimer", "domain", "domain_id", "registered?", "available?", "created_on", "updated_on", "expires_on",
    "registrar", "registrant_contacts", "admin_contacts", "technical_contacts", "nameservers"]
end
File.open('errors', 'w') {|file| file.truncate(0) }

File.readlines(input_filename).each do |url|
  sleep 2
  url = url.chomp.gsub(/www./,"")
  puts "Looking up WHOIS record for #{url}"

  ENV['http_proxy'] = "http://" + proxies_list[Random.rand(proxies_list.length)];
  puts "Proxy #{ENV['http_proxy']} is being used"

  c = Whois::Client.new
  begin
    r = c.lookup(url)
    if r.registered?
      puts ".....lookup successful, url found : #{url}"
    else
      puts ".....lookup successful, url NOT found : #{url}"
    end

    CSV.open(csv_file, "ab") do |csv|
      csv << [url, r.status, r.disclaimer, r.domain, r.domain_id, r.registered?, r.available?, r.created_on, r.updated_on, r.expires_on,
        format_registrar(r.registrar), format_contacts(r.registrant_contacts), format_contacts(r.admin_contacts), format_contacts(r.technical_contacts), format_name_servers(r.nameservers)]
    end
    puts ".....lookup successful, results are saved for #{url}"
  rescue Timeout::Error
    puts ".....lookup unsuccessful, request timed out"
  rescue
    puts r
    File.open('errors', 'a') { |f| f.write("#{url}\n") }
    # puts ".....lookup unsuccessful, unknown error"
  end
end
