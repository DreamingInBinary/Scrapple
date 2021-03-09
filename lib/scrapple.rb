# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'
require 'json'

# All of Apple's docs do a request for json, which makes all of this easier.
# This current code gets all of the framework json, and from there it's just
# A matter of parsing that and getting the docs recursively for each.

# Next up: Get docs appending to array correctly

class Scrapple < Kimurai::Base
  @engine = :selenium_firefox
  @start_urls = ['https://developer.apple.com/tutorials/data/documentation/technologies.json']
  @config = {
    disable_images: true,
    skip_duplicate_requests: true,
    retry_request_errors: [Net::HTTPNotFound]
  }
  
  def parse(response, url:, data: {})
    
    scrape_accelerate_only = 1
    framework_data = JSON.parse(response.css("div#json")[0])["references"]
    sorted_frameworks = Array.new

    # Find every framework to crawl
    framework_data.each do |key, value|
      if value.has_key?("title") && value.has_key?("abstract")
        framework_data = {}
        framework_data["name"] = value["title"]
        framework_data["href"] = value['url']
        framework_data["descriptions"] = value["abstract"][0]["text"]
        framework_data["href_json"] = 'https://developer.apple.com/tutorials/data' + "#{framework_data["href"]}" + '.json'
        framework_data["docs"] = {}
        sorted_frameworks.push(framework_data)
      end 
    end

    # Sort them by name and save off to json to append later
    frameworks_hash = {}
    sorted_frameworks.sort_by! { |topic| topic["name"].downcase }
    sorted_frameworks.each do |val|
      frameworks_hash[val["name"]] = val
    end
    File.write('results.json', JSON.dump(frameworks_hash))

    # Begin crawl
    if scrape_accelerate_only
      test_data = sorted_frameworks.select { |data| data["name"] == "Contacts UI" }[0]
      if test_data.empty? == false 
        request_to :parse_framework, url: test_data["href_json"].to_s, data: { name: test_data["name"] }
      end
    else

    end

  end

  def parse_framework(response, url:, data: {})
    # Get all role:symbol
    # Get all role:collectionGroup to deep search

    # Parse out response json, strip uselss keys
    framework_json = JSON.parse(response.css("div#json")[0])["references"]
    stripped_keys = framework_json.map { |k,v| v }

    # Append to current json
    current_json = File.read("results.json")
    frameworks_hash = JSON.parse(current_json)
    framework_hash = frameworks_hash[data[:name]]

    # Save any symbols
    symbols = stripped_keys.select { |symbol| symbol["kind"].downcase == "symbol" }
    symbols.each do |symbol|
      framework_hash["docs"][symbol["title"]] = symbol
    end 

    # Save back to json
    frameworks_hash[data[:name]] = framework_hash
    File.write('results.json', JSON.dump(frameworks_hash))
  end

  def parse_symbol(response, url:, data: {})

  end
  
end

Scrapple.crawl!
