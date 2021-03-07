# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'

# All of Apple's docs do a request for json, which makes all of this easier.
# This current code gets all of the framework json, and from there it's just
# A matter of parsing that and getting the docs recursively for each.

class Scrapple < Kimurai::Base
  @engine = :selenium_firefox
  @start_urls = ['https://developer.apple.com/documentation/technologies']
  @config = {
    disable_images: true,
    skip_duplicate_requests: true,
    retry_request_errors: [Net::HTTPNotFound]
  }
  
  def parse(response, url:, data: {})
    browser.execute_script("window.scrollBy(0,1000)") ; sleep 1
    response = browser.current_response

    # For testing, set this to 1 to only crawl the first frameowk
    onlySearchFirst = 1
    xpathToken = "//*[@id=\"main\"]/section/ul/li/a"

    found = response.xpath(xpathToken).length
    puts "Found #{found} frameworks}"

    if found < 1 
      puts "Returning since no frameworks were found."
      return 
    end

    response.xpath(xpathToken).each do |framework|
      framework_data = {}
      framework_data[:name] = framework.css("div.card__content p").text
      framework_data[:description] = framework.css("div.card__abstract").text 
      framework_data[:href] = framework['href']
      clean_href = framework_data[:href].downcase
      clean_href = clean_href.to_s
      clean_href.gsub!(" ","_")
      framework_data[:href_json] = 'https://developer.apple.com/tutorials/data' + clean_href + '.json'

      save_to "results.json", framework_data, format: :pretty_json

      #request_to :parse_framework, url: framework_data[:href]

      break if onlySearchFirst == 1
    end

  end

  def parse_framework(response, url:, data: {})
    browser.execute_script("window.scrollBy(0,5000)") ; sleep 1
    response = browser.current_response

    puts "Parsing symbols for #{url.to_s}, #{response.css("div.link-block.topic").count} potential symbols found...."

    <<~aid
    Here we can find four different things:
    - API Reference: These link to more symbols. We need to visit that link and crawl it in parse_symbol
    -
    aid

    response.css("div.link-block.topic").each do |apiRef|
      next unless apiRef.css("title").length > 0

      if apiRef.css("title").select{|link| link.text == "API Reference"}.length > 0
          framework_link = 'https://developer.apple.com' + apiRef.css("a")[0]['href']
          request_to :parse_symbol, url: framework_link
      end

      rescue StandardError => e
        puts "Failed parsing a framework symbol for #{url.to_s}: (#{e.inspect}), moving on."
    end

    puts "\n\n"
  end

  def parse_symbol(response, url:, data: {})
    browser.execute_script("window.scrollBy(0,2000)") ; sleep 1
    response = browser.current_response

    framework_symbols = {}
    puts "Crawling API Reference for #{url.to_s}..."

    response.css("div.link-block.topic").each do |symbol|
      if symbol.css("a.link.has-adjacent-elements").length > 0
        matched_symbol = {}
        matched_symbol[:type] = symbol.css("span.decorator")[0].text
        matched_symbol[:name] = symbol.css("span.identifier")[0].text
        matched_symbol[:overview] = symbol.css("div.content")[0].text
        puts "Symbol parsed: #{matched_symbol.inspect}"
        framework_symbols["#{matched_symbol[:name]}"] = matched_symbol
      end
    end

    rescue StandardError => e
        puts "Failed parsing a symbol for #{url.to_s}: (#{e.inspect}), moving on."

    save_to "results.json", framework_symbols, format: :pretty_json
  end
  
end

Scrapple.crawl!
