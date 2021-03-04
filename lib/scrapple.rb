# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'
require 'json'

class Scrapple < Kimurai::Base
  @engine = :selenium_firefox
  @start_urls = ['https://developer.apple.com/documentation/technologies']
  @config = {
    skip_duplicate_requests: true,
    retry_request_errors: [Net::HTTPNotFound]
  }

  def parse(response, url:, data: {})
    # Due to the docs being generated using next.js - wait a few seconds for them to be ready to crawl.
    sleep 2
  
    File.open("tmp.json","w") do |f|
      f.write("{\"frameworks\": {")
    end
    
    Parallel.each(response.css('ul.list li')) do |framework|
      framework_data = {}
      framework_data[:name] = framework.css("div.card__content").css("p").text
      framework_data[:description] = framework.css("div.card__content").css("div.card__abstract").text
      framework_data[:href] = 'https://developer.apple.com' + framework.css("a.card")[0]['href']
      
      # puts "#{framework_data.inspect}"
      
      # Next up - See how to know when request is done, and append valid JSON braackets. Crawl each framework -> each symbol -> write to .json
      File.open("tmp.json","a") do |f|
        f.write("\"#{framework_data[:name]}\":" + "#{framework_data.to_json}" + ',')
      end
      
    rescue StandardError => e
      puts "Failed a request for the #{framework_data[:name].to_s} framework: (#{e.inspect}), moving on."

    end
  end

  def parse_framework(response, url:, data: {})
  end

  def parse_symbol(response, url:, data: {})
  end
  
end

Scrapple.crawl!
