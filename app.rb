c = Whois::Client.new
r = c.lookup("google.com")
# => #<Whois::Record>

puts r
