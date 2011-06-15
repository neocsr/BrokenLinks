require File.expand_path(File.dirname(__FILE__) + '/../lib/spider.rb')

describe "Spider" do
  it "Should print 'Starting spider...' on start" do
    spider = Spider.new
    message = spider.start
    message.should == 'Starting spider...'
  end
end