# Author::    Simone Dall'Angelo (simone@wonsys.net), Michele Finotto (michele@wonsys.net), Matteo Nodari (matteo@wonsys.net)
# Copyright:: Copyright (c) 2008 Wonsys S.r.l.
# License::   BSD License

require File.join(File.dirname(__FILE__), 'Page.rb')

# == Introduction
# This class fetches and parses DeviantART User's Journal page.
#
# == Use
# To use DailyDev you have simply to create a new instance of UserJournal. Something like that:
#
#   empty_instance_of_user_journal = UserJournal.new
#
# To populate journal_data you have to call get_data method:
#
#   data = empty_instance_of_user_journal.get_data
#
# You can also specify if you want that the parsing has to start immediately after the initialization:
#
#   instance_of_user_journal_filled_with_parsed_data = UserJournal.new(nickname, true)
class UserJournal < Page
  
  # User's nickname to fetch.
  attr_reader :nickname
  
  # Page's url to fetch (set at inizialization).
  attr_reader :url
  
  # It contains all parsed data.
  attr_reader :journal_data
  
  # it contains the raw page (parsed by hpricot)
  attr_reader :page
  
  # Initializes and calls nickname= method.
  #
  # If parse_now is set to true the method fetches and parses data.
  #
  # It returns a UserJournal instance.
  #
  # Note: if parse_now is set to true it sets total_time too.
  def initialize(nickname, parse_now = false)
    @parse_time = nil
    @journal_data = []
    self.nickname = nickname  # Sets @nickname and @url
    if parse_now
      @page = fetch_url(@url)
      @parse_time = parse_journal_page
      @page = nil # To flush @page content and free memory
    end
  end
  
  # Sets nickname and url.
  # If value is not valid raises an ArgumentError exception.
  def nickname=(value)
    if value && value.is_a?(String)
      @nickname = value
      @url_prepend = "http://#{nickname}.deviantart.com"
      @url = "#{@url_prepend}/journal/"
    else
      raise ArgumentError
    end
  end
  
  # Fetches and parses data populating journal_data hash.
  #
  # It returns the time elapsed (calling total_time method).
  def get_data
    if @nickname && @url
      @page = fetch_url(@url)
      @parse_time = parse_journal_page
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
  
  # Parses journal page and populates journal_data.
  def parse_journal_page
    start = Time.now
    
    entries = @page.search('.pp.mglist li')
    if entries.any?
      entries.each do |e|
        @journal_data << { :title => e.search('.main').inner_text, :date => e.search('.side').inner_text, :url => @url_prepend + "#{e.search('.main a').first.attributes['href']}"}
      end
    end
    
    Time.now - start
  end
end