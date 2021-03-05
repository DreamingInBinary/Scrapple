# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'

# TODO: Sometimes, some frameworks are never found even with the same code that does find them.
# TODO: Get xpath for symbols of each framework.

class Scrapple < Kimurai::Base
  @engine = :selenium_firefox
  @start_urls = ['https://developer.apple.com/documentation/technologies']
  @config = {
    disable_images: true,
    skip_duplicate_requests: true,
    retry_request_errors: [Net::HTTPNotFound]
  }
  
  def parse(response, url:, data: {})
    # For testing, set this to 1 to only crawl the first frameowk
    onlySearchFirst = 0
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
      framework_data[:href] = 'https://developer.apple.com' + framework['href']

      save_to "results.json", framework_data, format: :pretty_json

      request_to :parse_framework, url: framework_data[:href]

      break if onlySearchFirst == 1
    end

  end

  def parse_framework(response, url:, data: {})
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
