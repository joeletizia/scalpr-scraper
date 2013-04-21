#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'csv'
require 'socksify'
require 'socksify/http'
require 'tor-privoxy'

class Webscrape
  def self.scrape_craigslist(city="sanfrancisco")
    ##CONFIGURATION
    cl_category = "tia"
    ##END CONFIG
    url = "http://#{city}.craigslist.org/#{cl_category}/"
    puts "Connecting..."
    agent = Mechanize.new
      puts "Mechanize Started!"
      searchpage = agent.get(url)
      index = 0
      results_array = []
      keep_going = true
      while keep_going == true or index < 1000000 #will never go over a million
        puts "Current results: #{results_array.length}"
        index_term = (index != 0) ? "index" + index.to_s + ".html" : ""
        searchpage = agent.get(url+index_term)
        puts "searching #{url} term: #{index_term}"
        safe_links = searchpage.links.reject{|l| l.attributes.parent.attributes['class'].nil?}
        links = safe_links.find_all { |l| l.attributes.parent.attributes['class'].value == 'pl' }
        if links.size < 2
          puts "last page!"
          keep_going = false
        end
        puts "found #{links.length} on page"
        links.each do |l|
          new_page = l.click
          puts "navigating to #{l.href}"
          table = new_page.parser.xpath('//section[@class="userbody"]')
          text =  table.inner_text.to_s
          number = /[\(\.\- ]*[0-9]{3}[\)\.\- ]*[0-9]{3}[\-\. ]*[0-9]{4}/.match(text)
          puts "searching for phone number"
          if number
            content = text.gsub(/\s+/," ")
            puts "number: " + number.to_s
            results_array.push [number, content]
          end
        end
        index += 100
      end
      CSV.open("craigslist.csv", "a") do |csv|
        results_array.each do |row|
          csv << row
        end
      end
  end
end

if __FILE__ == $0
  if ARGV.size > 0
    File.open( ARGV[0] ).each_line do |line| 
      Webscrape.scrape_craigslist( line.strip )
    end
  else
    Webscrape.scrape_craigslist
  end
end

