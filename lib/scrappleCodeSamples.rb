require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'
require 'json'

# Get all of all Apple's code samples from their docs.
class ScrappleCodeSamples < Kimurai::Base
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
    FileUtils.mkdir_p 'Apple Crawl Data/Code Samples/'
    sorted_frameworks.sort_by! { |topic| topic["name"].downcase }
    sorted_frameworks.each do |f|
      file_name = sanitize_filename "#{f["name"]}"
      f_hash = {"code":{}}

      if File.exist?("Apple Crawl Data/Code Samples/#{file_name}.json") == false
        File.write("Apple Crawl Data/Code Samples/#{file_name}.json", JSON.dump(f_hash))
      end
    end

    # Begin crawl
    if scrape_test_only == 1
      test_data = sorted_frameworks.select { |data| data["name"] == "App Clips" }[0]
      if test_data.empty? == false 
        request_to :parse_framework, url: test_data["href_json"].to_s, data: { name: test_data["name"] }
      end
    else
      sorted_frameworks.each do |current_framework|
        sleep 1
        request_to :parse_framework, url: current_framework["href_json"].to_s, data: { name: current_framework["name"] }
      end
    end

    rescue StandardError => e
        puts "There is failed request (#{e.inspect}) at #{e.backtrace}, skipping it..."
  end

  def parse_framework(response, url:, data: {})
    # Get all role:symbol
    # Get all role:collectionGroup to deep search
    f_name = data[:name]

    puts "🚀 for the #{f_name} framework..."

    framework_json = (JSON.parse(response.css("div#json")[0])["references"] || {})
    framework_metadata = (JSON.parse(response.css("div#json")[0])["metadata"] || {})
    stripped_keys = framework_json.map { |k,v| v }

    # Ensure we're in the right framework still, some articles branch out to other ones
    is_right_framework = (framework_metadata["title"] || "") == f_name 
    if is_right_framework == false && framework_metadata.key?("modules") == true
      if framework_metadata["modules"][0] != nil
        modules = framework_metadata["modules"][0]
        if modules["name"] == f_name 
          is_right_framework = true 
        end
      end
    end

    if is_right_framework == false 
      puts "⛔️ Wrong #{framework_metadata} for #{f_name} at #{url}"
      return
    end

    # Find any existing articles on this page, they might have code samples linked
    articles = stripped_keys.select { |x| (x["kind"] || "").downcase == "article" }
    articles.each do |symbol|
      # Save back to json
      if (symbol["role"] || "").downcase == "samplecode"
        file_name = sanitize_filename f_name
        current_json = File.read("Apple Crawl Data/Code Samples/#{file_name}.json")
        framework_hash = JSON.parse(current_json)
        framework_hash["code"][symbol["title"]] = symbol
        File.write("Apple Crawl Data/Code Samples/#{file_name}.json", JSON.dump(framework_hash))
      end

      # They might have articles within articles
      if symbol.key?("url")
        clean_url = symbol["url"].gsub(/[#\d]/,"")
        request_to :parse_framework, url: 'https://developer.apple.com/tutorials/data' + clean_url + '.json', data: { name: f_name }
      end
    end

    # Also get the new spiffy tutorials
    modern_tuts = stripped_keys.select { |x| (x["kind"] || "").downcase == "overview" }
    modern_tuts.each do |symbol|
      # Save back to json
      if (symbol["role"] || "").downcase == "overview"
        file_name = sanitize_filename f_name
        current_json = File.read("Apple Crawl Data/Code Samples/#{file_name}.json")
        framework_hash = JSON.parse(current_json)
        framework_hash["code"][symbol["title"]] = symbol
        File.write("Apple Crawl Data/Code Samples/#{file_name}.json", JSON.dump(framework_hash))
      end
    end

    # Crawl collectionGroup recursively
    collection_groups = stripped_keys.select { |cg| (cg["role"] || "").downcase == "collectiongroup" }
      collection_groups.each do |cg|
      next unless (cg["url"] || "") != ""

      puts "🔎 -> #{f_name} has a collection group at #{cg["url"].to_s}"
      request_to :parse_framework, url: 'https://developer.apple.com/tutorials/data' + cg["url"].to_s + '.json', data: { name: f_name }
    end

    rescue StandardError => e
      puts "\n\n🚨 There is failed request to #{f_name} - " + url.to_s + " (#{e.inspect}), skipping it...\n\n"
  end

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-z.\-]/, '_')
  end
  
end

ScrappleCodeSamples.crawl!
