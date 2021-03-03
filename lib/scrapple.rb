# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'net/http'
require 'parallel'
require 'kimurai'
require 'nokogiri'
require 'odyssey'

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
  
    Parallel.each(response.css('div.card__content p')) do |framework|
      
      puts "#{framework["aria-label"]}"
      
      # Next up - crawl each framework -> each symbol -> write to .json

    rescue StandardError => e
      puts "🚨 Failed a request for the #{framework["aria-label"]} framework: (#{e.inspect}), moving on."
    end
  end

  def parse_framework(response, url:, data: {})
  end

  def parse_symbol(response, url:, data: {})
  end
  
end

Scrapple.crawl!
