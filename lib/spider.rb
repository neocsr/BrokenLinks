require 'rubygems'
require 'thread'

queue = Queue.new


5.times do |i|
  sleep rand(i*2) # simulate expense
  queue << i
  puts "#{i} produced"
end

consumer = Thread.new do
  5.times do |i|
    value = queue.pop
    sleep rand(i/2) # simulate expense
    puts "consumed #{value}"
  end
end

consumer.join
