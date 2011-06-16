require 'net/http'
require File.expand_path(File.dirname(__FILE__) + '/../lib/status_codes')

class Spider
  def initialize(name, output=STDOUT)
    @output = output
    @name   = name
  end

  def setup
    @output.puts "Current spider '#{@name}'"

    @info = {
      :url           => nil,
      :spider_name   => nil,
      :response_code => nil,
      :response_time => nil,
      :error         => nil,
      :error_detail  => nil
    }
  end

  def process_url(url)
    setup

    begin
      uri = URI.parse(url)
      @info[:url] = url
      @info[:spider_name] = @name

      raise "Invalid host name. Forgot to include 'http://'?" if uri.host.nil?

      start_time = Time.now
      response = Net::HTTP.get_response(uri)
      end_time = Time.now

      response_code = response.code.to_i

      @info[:response_code] = response_code
      @info[:response_time] = end_time - start_time
      @info[:error]         = false
      @info[:error_detail]  = ""

      if response_code >= 400
        @info[:error]        = true
        @info[:error_detail] = StatusMessage[response_code]
      end

    rescue => error
      @output.puts error.message
    
      @info[:response_code] = ""
      @info[:response_time] = 0
      @info[:error]         = true
      @info[:error_detail]  = error.message
    end

    @info
  end
end