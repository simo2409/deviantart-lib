# Author::    Simone Dall'Angelo (simone@wonsys.net), Michele Finotto (michele@wonsys.net), Matteo Nodari (matteo@wonsys.net)
# Copyright:: Copyright (c) 2008 Wonsys S.r.l.
# License::   BSD License

require File.join(File.dirname(__FILE__), 'Page.rb')

# == Introduction
# This class fetches and parses DeviantART's Today page.
#
# It uses http://today.deviantart.com/ as url.
#
# Note: The url is encoded in the class and is not possible to change it.
#
# == Use
# To use SiteToday you have simply to create a new instance of SiteToday. Something like that:
#
#   empty_instance_of_site_today = SiteToday.new
#
# To populate today_data you have to call get_data method:
#
#   data = empty_instance_of_site_today.get_data
#
# You can also specify if you want that the parsing has to start immediately after the initialization:
#
#   instance_of_site_today_filled_with_parsed_data = SiteToday.new(true)

class SiteToday < Page
  
  # Page's url to fetch (set at inizialization).
  attr_reader :url
  
  # It contains all parsed data.
  attr_reader :today_data
  
  # it contains the raw page (parsed by hpricot)
  attr_reader :page
  
  # Initializes and calls nickname= method.
  #
  # If parse_now is set to true the method fetches and parses data.
  #
  # It returns a SiteToday instance.
  #
  # Note: if parse_now is set to true it sets total_time too.
  def initialize(parse_now = false)
    @parse_time = nil
    @today_data = Hash.new
    @url = "http://today.deviantart.com/"
    if parse_now
      @page = fetch_url(@url)
      @parse_time = parse_today_page
      @page = nil # To flush @page content and free memory
    end
  end
  
  # Fetchs and parse data populating today_data hash.
  #
  # It returns the time elapsed (calling total_time method).
  def get_data
    if @url
      @page = fetch_url(@url)
      @parse_time = parse_today_page
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
  
  # Parses daily deviations page and populates today_data.
  def parse_today_page
    start = Time.now
    # Parse moods
    moods_labels = @page.search('dl .f .graph dd')
    moods_counters = @page.search('dl .f .graph dt')
    moods_images = @page.search('dl .f .graph img')
    moods = Hash.new
    if mood_labels.any?
      moods_labels.each_with_index do |label, cont|
        moods[label.inner_text.downcase.to_sym] = moods_counters[cont].inner_text.strip
        # moods_images[cont].attributes['src'] # Image path
      end
    end
    @today_data[:moods] = moods
    # End Parse moods
    
    # Popular journals
    items = @page.search('.pppt .iconleft .abridged .userjournal')
    journals = Array.new
    if items.any?
      items.each do |item|
        journals << { :title => item.search('h3').inner_text, :author => item.search('a .u').inner_text, :url => item.search('h3 a').first.attributes['href'] }
      end
    end
    @today_data[:popular_journals] = journals
    # End Popular journals
    
    # Last x seconds
    last_comments = @page.search('.c .block .pppt .u')
    last_comments_images = @page.search('.c .block .pppt .shadow a')
    comments = Array.new
    if last_comments.any?
      last_comments.each_with_index do |item, cont|
        comments << { :author => item.inner_text, :url => last_comments_images[cont].attributes['href'] }
      end
    end
    @today_data[:last_comments] = comments
    # End Last x seconds
    
    # Deviousness
    deviousness = @page.search('.block .pppt .ppb')
    @today_data[:deviousness] = { :nickname => deviousness.search('a .u').first.inner_text, :text => deviousness.search('p').inner_text } if deviousness.any?
    # End Deviousness
    
    # Daily deviations
    daily_deviations = @page.search('.pppt h3')[11].inner_text
    if daily_deviations.any?
      daily_deviations = daily_deviations[0..(daily_deviations.size-18)]  # Elimina ' Daily Deviations' dal fondo
    end
    @today_data[:daily_deviations] = daily_deviations
    # End Daily deviations
    
    # Deviants online
    deviants_online = @page.search('.flatview .section')
    
    total_deviants_online = deviants_online.search('h3').first.inner_text
    total_deviants_online = total_deviants_online[0..(total_deviants_online.size-17)]
    
    kinds = Array.new
    kind_deviants_online = deviants_online.search('.ppppb .block ul .f li .f')
    
    kinds = kind_deviants_online.map { |item| /^\s*(\d{1,3}(,\d{3})?)(( +\w+){1,2}) *$/.match(item.inner_text)}.compact.inject({}) { |hash, b| hash.merge!({ b[3].strip.downcase.to_sym => b[1] }) }
    
    @today_data[:deviants_online] = kinds
    @today_data[:total_deviants_online] = total_deviants_online
    # End Deviants online
    
    # Popular forum threads
    popular_threads = @page.search('.flatview .section h3').select { |a| a.inner_text == 'Popular Forum Threads' }.first.parent
    popular_threads = popular_threads.search('li')
    threads = Array.new
    popular_threads.each do |item|
      links = item.search('a')
      threads << { :title => links[0].inner_text, :url => links[0].attributes['href'], :author => links[1].inner_text, :replies => item.search('span').inner_text.strip.match(/^\((\d{1,3}(,\d{3})?) replies\)$/)[1]}
    end
    @today_data[:popular_threads] = threads
    # End Popular forum threads
    
    # Popular user polls
    popular_polls = @page.search('.flatview .section h3').select { |a| a.inner_text == 'Popular User Polls' }.first.parent
    popular_polls = popular_polls.search('li')
    polls = Array.new
    popular_polls.each do |item|
      links = item.search('a')
      polls << { :title => links[0].inner_text, :url => links[0].attributes['href'], :author => links[1].inner_text, :votes => item.search('span').inner_text.strip.match(/^\((\d{1,3}(,\d{3})?) votes\)$/)[1]}
    end
    @today_data[:popular_polls] = polls
    # End Popular user polls
    
    # New deviants
    new_deviants = @page.search('.flatview .section h3').select { |a| a.inner_text == 'New Deviants' }.first.parent
    new_deviants = new_deviants.search('li')
    deviants = Array.new
    new_deviants.each do |item|
      deviants << item.search('a .u').inner_text
    end
    @today_data[:new_deviants] = deviants
    # End New deviants
    
    # Popular Deviants Today
    popular_deviants = @page.search('.flatview .section h3').select { |a| a.inner_text == 'Popular Deviants Today' }.first.parent
    popular_deviants = popular_deviants.search('li')
    deviants = Array.new
    popular_deviants.each do |item|
      deviants << item.search('a .u').inner_text
    end
    @today_data[:popular_deviants] = deviants
    # End Popular deviants today
    
    Time.now - start
  end
end