require 'rubygems'
require 'thread'
require 'lib/spider'

# Config
THREADS = 5
SLEEP   = 1
threads = []
spiders = []
ankens_with_error = []

# Datasource
URLS = [
  {:anken_id => 1, :anken_title => "value1", :anken_url => "http://www.google.com" },
  {:anken_id => 2, :anken_title => "value2", :anken_url => "http://www.google.com" },
  {:anken_id => 3, :anken_title => "value1", :anken_url => "http://www.google.com" },
  {:anken_id => 4, :anken_title => "value2", :anken_url => "http://www.google.com" },
  {:anken_id => 5, :anken_title => "value1", :anken_url => "http://www.google.com" },
  {:anken_id => 6, :anken_title => "value2", :anken_url => "http://www.google.com/test" }
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

puts "Here 1"

threads.each do |th|
  th.join
end

puts "Here 2"

puts ankens_with_error.inspect