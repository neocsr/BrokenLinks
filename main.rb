require 'rubygems'
require 'thread'
require 'yaml'
require 'lib/spider'
require 'lib/generic_mailer'
require 'active_record'

# Config
ENVIRONMENT = "test" # "test|development|production"
THREADS = 5
SLEEP   = 0.2
threads = []
spiders = []
ankens_with_error = []
excluded_urls = File.readlines("excluded_urls.txt").map{|x| x.strip}
excluded_url = nil

start_time = Time.now

# Datasource
db_config = YAML::load_file("config/database.yml")

ActiveRecord::Base.establish_connection(db_config[ENVIRONMENT])

class SpiderUrl < ActiveRecord::Base
  set_table_name "TBL_S_BLOCK_URL"
  set_primary_key  "S_BLOCK_URL_ID"
end

URLS = SpiderUrl.find(:all, :limit => 200)

puts "Initial Urls: #{URLS.size}"

# Filter urls
while (excluded_url = excluded_urls.pop)
  URLS.delete_if do |x| 
    if x["S_BLOCK_URL"] == excluded_url 
      puts "Deleted: #{excluded_url}"
      true
    end
  end
end

puts "Filtered Urls: #{URLS.size}"

# Queues
source_queue = Queue.new
result_queue = Queue.new

URLS.each do |anken|
  source_queue.push(anken.attributes) # Just save the hashes, not the AR objects.
end

# Threads setup
0.upto(THREADS - 1) do |i|
  threads << Thread.new(i) do |j|
    spiders << Spider.new(j)
    
    while source_queue.size > 0

      if spiders[j]
        anken = source_queue.pop
        info = spiders[j].process_url(anken["S_BLOCK_URL"])
        puts info[:response_code]
        ankens_with_error << anken.merge(info) if info[:error]
      end

      sleep SLEEP

    end

  end
end

threads.each do |th|
  th.join
  # Wait for the thread to finish if it isn't this thread (i.e. the main thread).
  # th.join if th != Thread.current
end

puts "Preparing email..."

attachment = "urls_check_#{Time.now.strftime('%Y%m%d')}.csv"
file = File.open(attachment, 'w+')

file.puts "URL ID, URL TITLE, URL, REGISTERED DATE, RESPONSE CODE, ERROR DETAIL "

ankens_with_error.each do |anken|
  row_data = "#{anken['S_BLOCK_URL_ID']}, #{anken['S_BLOCK_URL_NAME']}, " +
             "#{anken['S_BLOCK_URL']}, " +
             "#{anken['UP_DATE'] ? anken['UP_DATE'].strftime('%Y-%m-%d') : nil}, " +
             "#{anken[:response_code]}, #{anken[:error_detail]}"
  file.puts row_data
end

file.close

# Send summary mail
smtp_config = YAML::load_file("config/smtp.yml")

from_address = smtp_config[ENVIRONMENT]["from_address"]
to_addresses = smtp_config[ENVIRONMENT]["to_addresses"]
subject = "URL Check: #{Time.now.strftime('%Y-%m-%d')}"
body = <<EOF
レポート
======

「全てのURL」 #{URLS.size}件
「エラーURL」 #{ankens_with_error.size}件

日付 #{Time.now.strftime('%Y-%m-%d')}

EOF

mailer = GenericMailer.new
mailer.start(smtp_config[ENVIRONMENT])
mailer.send_message(from_address, to_addresses, subject, body, attachment)
mailer.finish

puts "Email sent..."

end_time = Time.now
delay = end_time - start_time
puts "Report in #{(delay/60).to_i}m #{delay % 60}s"
