require File.expand_path(File.dirname(__FILE__) + '/../lib/spider.rb')

describe "Spider" do
  before(:each) do
    @output = double('output').as_null_object
    @spider = Spider.new(1, @output)
    @valid_url = "http://www.google.com"
    @invalid_url = "www.google.com"
  end

  it "Should print 'Current spider {{name}}' on setup" do
    @output.should_receive(:puts).with("Current spider '1'")
    @spider.setup
  end

  it "Should accept a valid URL as an input and return a hash of values" do
    info = @spider.process_url(@valid_url)
    puts info.inspect

    info[:url].should eq(@valid_url)
    info[:spider_name].should eq(1)
    info[:response_code].should eq(200)
    info[:response_time].should be > 0
    info[:error].should be_false
    info[:error_detail].should eq("")
  end

  it "Should accept an invalid URL as an input and return a hash with errors" do
    info = @spider.process_url(@invalid_url)
    info[:url].should eq(@invalid_url)
    info[:spider_name].should eq(1)
    info[:response_code].should eq("")
    info[:response_time].should eq(0)
    info[:error].should be_true
    info[:error_detail].should_not eq("")
    puts info.inspect
  end

  it "Should report an 'error_detail' if the response_code is greater than 400" do
    info = @spider.process_url("http://www.google.com/test")
    puts info.inspect

    info[:response_code].should >= 400
    info[:error].should be_true
    info[:error_detail].should_not eq("")
  end
end