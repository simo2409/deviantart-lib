# Author::    Simone Dall'Angelo (simone@wonsys.net), Michele Finotto (michele@wonsys.net), Matteo Nodari (matteo@wonsys.net)
# Copyright:: Copyright (c) 2008 Wonsys S.r.l.
# License::   BSD License

require File.join(File.dirname(__FILE__), 'Page.rb')

# == Introduction
# This class fetches and parses DeviantART's Daily Deviations page.
#
# It uses http://today.deviantart.com/dds/ as url.
#
# Note: The url is encoded in the class and is not possible to change it.
#
# == Use
# To use DailyDev you have simply to create a new instance of DailyDev. Something like that:
#
#   empty_instance_of_daily_dev = DailyDev.new
#
# To populate daily_data you have to call get_data method:
#
#   data = empty_instance_of_daily_dev.get_data
#
# You can also specify if you want that the parsing has to start immediately after the initialization:
#
#   instance_of_daily_dev_filled_with_parsed_data = DailyDev.new(true)
class DailyDev < Page
  # Page's url to fetch (set at inizialization).
  attr_reader :url
  
  # It contains all parsed data.
  attr_reader :daily_data
  
  # it contains the raw page (parsed by hpricot)
  attr_reader :page
  
  # If parse_now is set to true the method fetches and parses data.
  #
  # It returns a DailyDev instance.
  #
  # Note: if parse_now is set to true it sets total_time too.
  def initialize(parse_now = false)
    @parse_time = nil
    @daily_data = Array.new
    @url = "http://today.deviantart.com/dds/"
    if parse_now
      @page = fetch_url(@url)
      @parse_time = parse_dailydev_page
      @page = nil # To flush @page content and free memory
    end
  end
  
  # Fetches and parses data populating daily_data hash.
  #
  # It returns the time elapsed (calling total_time method).
  def get_data
    if @url
      @page = fetch_url(@url)
      @parse_time = parse_dailydev_page
      @page = nil
      self.total_time
    end
  end
  
  # Returns total time elapsed to fetch and parse the content.
  #
  # Note: returns 0 if data is not fetched and parsed yet.
  def total_time
    (@fetch_time || 0) + (@parse_time || 0)
  end
  
  private
  
  # Parses daily deviations page and populates daily_data.
  def parse_dailydev_page
    start = Time.now
    items = @page.search('.ddinfo')
    if items.any?
      items.each do |item|
        desc = item.search('.foot').empty
        desc = item.inner_text.strip
        link_el = item.search('a').select { |item| /\/deviation\// === item.attributes['href'] }.first
        link = link_el.attributes['href']
        title = link_el.inner_text
        @daily_data << { :title => title, :desc => desc, :link => link }
      end
    end
    Time.now - start
  end
end