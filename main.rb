require 'whois'
require 'csv'
require 'yaml'

def yaml_clean(obj)
  return YAML::dump(obj).gsub(/\n/," ").gsub(/::/,"").gsub(/---/,"").gsub(/ ... /,"").gsub(/ - /,"").gsub(/!ruby\/struct/,"").gsub(/:WhoisRecord/,"")
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

File.readlines(input_filename).each do |url|
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
        yaml_clean(r.registrar), yaml_clean(r.registrant_contacts), yaml_clean(r.admin_contacts), yaml_clean(r.technical_contacts), yaml_clean(r.nameservers)]
    end
    puts ".....lookup successful, results are saved for #{url}"
  rescue Timeout::Error
    puts ".....lookup unsuccessful, request timed out"
  rescue
    puts ".....lookup unsuccessful, unknown error"
  end
end
