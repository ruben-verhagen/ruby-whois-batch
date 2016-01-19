require 'whois'

filename = ARGV[0];


File.readlines('urls.txt').each do |url|
  puts "Looking up WHOIS record for #{url}"
  c = Whois::Client.new

  begin
    r = c.lookup(url)
    if r.registered?
      puts ".....lookup successful, url registered : #{url}"
    else
      puts ".....lookup successful, url NOT registered : #{url}"
    end
    File.open(url, "w"){|to_file| Marshal.dump(r, to_file)}
  rescue Timeout::Error
    puts ".....lookup unsuccessful, request timed out"
  rescue
    puts ".....lookup unsuccessful, unknown error"
  end

end
