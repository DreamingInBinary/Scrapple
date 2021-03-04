# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'
require 'json'
require 'byebug'

# Next up, see why symbols aren't always found. Do I need to use xpath?

class Scrapple < Kimurai::Base
  @engine = :selenium_firefox
  @start_urls = ['https://developer.apple.com/documentation/technologies']
  @config = {
    user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 11.2; rv:86.0) Gecko/20100101 Firefox/86.0",
    skip_duplicate_requests: true,
    retry_request_errors: [Net::HTTPNotFound]
  }
  
  
  def parse(response, url:, data: {})
    #File.open("tmp.json","w") do |f|
    #  f.write("{\"frameworks\": {")
    #end
    
    requestOne = 1

    # For testing, hit only the first match
    if requestOne == 1
      framework = response.css("ul.list li")[13] #AppKit
      framework_data = {}
      framework_data[:name] = framework.css("div.card__content").css("p").text
      framework_data[:description] = framework.css("div.card__content").css("div.card__abstract").text
      framework_data[:href] = 'https://developer.apple.com' + framework.css("a.card")[0]['href']
        
      request_to :parse_framework, url: framework_data[:href]
    else
      puts "\n\nKicking off frameworks crawl, #{response.css("ul.list li").length} found...\n\n"
      response.css("ul.list li").each do |framework|
        framework_data = {}
        framework_data[:name] = framework.css("div.card__content").css("p").text
        framework_data[:description] = framework.css("div.card__content").css("div.card__abstract").text
        framework_data[:href] = 'https://developer.apple.com' + framework.css("a.card")[0]['href']
            
        #File.open("tmp.json","a") do |f|
        #  f.write("\"#{framework_data[:name]}\":" + "#{framework_data.to_json}" + ',')
        #end
        #puts "Request to #{framework_data[:href].to_s}"
        request_to :parse_framework, url: framework_data[:href]
      
        rescue StandardError => e
          puts "Failed a request for the #{framework_data[:name].to_s} framework: (#{e.inspect}), moving on."
      end
    end
  end

  def parse_framework(response, url:, data: {})
    puts "\n\n"
    puts "Parsing symbols for #{url.to_s}, #{response.css("div.link-block.topic").count} potential symbols found...."

    response.css("div.link-block.topic").each do |apiRef|
      if apiRef.css("title").select{|link| link.text == "API Reference"}.length > 0
          framework_link = apiRef.css("a")[0]['href']
          puts "#{framework_link.inspect}"
      end

      rescue StandardError => e
        puts "Failed parsing a symbol for #{url.to_s}: (#{e.inspect}), moving on."
    end

    puts "\n\n"
  end

  def parse_symbol(response, url:, data: {})
    # TODO
  end
  
end

Scrapple.crawl!
