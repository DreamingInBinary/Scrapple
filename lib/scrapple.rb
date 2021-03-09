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

# Next up: It doesn't seem to deep-search collection groups. For example, this was not found in Accelerate: https://developer.apple.com/documentation/accelerate/vdsp
# So compare that json with what I had and see why it doesn't make a request to it.

class Scrapple < Kimurai::Base
  @engine = :selenium_firefox
  @start_urls = ['https://developer.apple.com/tutorials/data/documentation/technologies.json']
  @config = {
    disable_images: true,
    skip_duplicate_requests: true,
    retry_request_errors: [Net::HTTPNotFound,Net::ReadTimeout,Net::HTTPBadGateway]
  }
  
  def parse(response, url:, data: {})
    
    scrape_test_only = 0
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

    # Sort them by name
    frameworks_hash = {}
    sorted_frameworks.sort_by! { |topic| topic["name"].downcase }
    sorted_frameworks.each do |f|
      file_name = sanitize_filename f["name"]
      f_hash = {"docs":{}}
      File.write("#{file_name}.json", JSON.dump(f_hash))
    end

    # Begin crawl
    if scrape_test_only == 1
      test_data = sorted_frameworks.select { |data| data["name"] == "Contacts UI" }[0]
      if test_data.empty? == false 
        request_to :parse_framework, url: test_data["href_json"].to_s, data: { name: test_data["name"] }
      end
    else
      sorted_frameworks.each do |current_framework|
        request_to :parse_framework, url: current_framework["href_json"].to_s, data: { name: current_framework["name"] }
      end
    end

    rescue StandardError => e
        puts "There is failed request (#{e.inspect}), skipping it..."
  end

  def parse_framework(response, url:, data: {})
    # Get all role:symbol
    # Get all role:collectionGroup to deep search
    f_name = data[:name]
    puts "🚀 for the #{f_name} framework..."

    # Parse out response json, strip uselss keys
    framework_json = (JSON.parse(response.css("div#json")[0])["references"] || {})
    stripped_keys = framework_json.map { |k,v| v }

    # Append to current json
    file_name = sanitize_filename f_name
    current_json = File.read("#{file_name}.json")
    framework_hash = JSON.parse(current_json)

    # Save any symbols, the easy part
    symbols = stripped_keys.select { |symbol| (symbol["kind"] || "").downcase == "symbol" }
    symbols.each do |symbol|
      next unless (symbol["title"] || "") != ""
      framework_hash["docs"][symbol["title"]] = symbol
    end 

    # Save back to json
    File.write("#{file_name}.json", JSON.dump(framework_hash))

    # Crawl collectionGroup recursively
    collection_groups = stripped_keys.select { |cg| (cg["role"] || "").downcase == "collectiongroup" }
    collection_groups.each do |cg|
      next unless (cg["url"] || "") != ""
      request_to :parse_framework, url: 'https://developer.apple.com/tutorials/data' + cg["url"].to_s + '.json', data: { name: f_name }
    end 

    rescue StandardError => e
        puts "\n\nThere is failed request to #{f_name} - " + url.to_s + " (#{e.inspect}), skipping it...\n\n"
  end

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-z.\-]/, '_')
  end
  
end

Scrapple.crawl!
