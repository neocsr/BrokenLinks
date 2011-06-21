require 'rubygems'
require 'thread'
require 'yaml'
require 'lib/spider'
require 'lib/generic_mailer'
require 'active_record'

# Config
ENVIRONMENT = "development"
THREADS = 5
SLEEP   = 1
threads = []
spiders = []
ankens_with_error = []

# Datasource

URLS = [
  {:anken_id => 1, :anken_title => "value1", :anken_url => "http://www.google.com" },
  #{:anken_id => 2, :anken_title => "value2", :anken_url => "http://www.google.com" },
  #{:anken_id => 3, :anken_title => "value3", :anken_url => "http://www.google.com/1234" },
  #{:anken_id => 4, :anken_title => "value4", :anken_url => "http://www.google.com" },
  #{:anken_id => 5, :anken_title => "value5", :anken_url => "http://www.google.com" },
  #{:anken_id => 6, :anken_title => "value6", :anken_url => "http://www.google.com/test" }
]

# Queue
queue = Queue.new

URLS.each do |anken|
  queue.push(anken)
end

# Threads setup
0.upto(THREADS - 1) do |i|
    threads << Thread.new(i) do
      spiders << Spider.new(i)
      while queue.size > 0
        anken = queue.pop
        info = spiders[i].process_url(anken[:anken_url])
        ankens_with_error << anken if info[:error]
        sleep SLEEP
      end
    end
end

threads.each do |th|
  th.join
end

puts ankens_with_error.inspect

# Send summary mail
smtp_config = YAML::load_file("config/smtp.yml")

from_address = "kevin@bitparagon.com"
to_addresses = "neocsr@gmail.com"
subject = "Summary"
body = <<EOF
Thank you for your attention.
EOF
attachment = "spec/energy.png"

mailer = GenericMailer.new
mailer.start(smtp_config[ENVIRONMENT])
mailer.send_message(from_address, to_addresses, subject, body, attachment)
mailer.finish

puts "Report finished in xxx seconds."
