# Author::    Simone Dall'Angelo (simone@wonsys.net), Michele Finotto (michele@wonsys.net), Matteo Nodari (matteo@wonsys.net)
# Copyright:: Copyright (c) 2008 Wonsys S.r.l.
# License::   BSD License

require File.join(File.dirname(__FILE__), 'Page.rb')

# == Introduction
# This class fetches and parses DeviantART User's Profile page.
#
# == Use
# To use UserProfile you have simply to create a new instance of UserProfile. Something like that:
#
#   empty_instance_of_user_profile = UserProfile.new
#
# To populate profile_data you have to call get_data method:
#
#   data = empty_instance_of_user_profile.get_data
#
# You can also specify if you want that the parsing has to start immediately after the initialization:
#
#   instance_of_user_profile_filled_with_parsed_data = UserProfile.new(nickname, true)
class UserProfile < Page
  
  # User's nickname to fetch.
  attr_reader :nickname
  
  # Page's url to fetch (set at inizialization).
  attr_reader :url
  
  # It contains all parsed data.
  attr_reader :profile_data
  
  # it contains the raw page (parsed by hpricot)
  attr_reader :page
  
  # Initializes and calls nickname= method.
  #
  # If parse_now is set to true the method fetches and parses data.
  #
  # It returns a UserProfile instance.
  #
  # Note: if parse_now is set to true itsets total_time too.
  def initialize(nickname, parse_now = false)
    @parse_time = nil
    @profile_data = Hash.new
    self.nickname = nickname  # Sets @nickname and @url
    if parse_now
      @page = fetch_url(@url)
      @parse_time = parse_profile_page
    end
  end
  
  # Sets nickname and url
  # If value is not valid raises an ArgumentError exception.
  def nickname=(value)
    if value && value.is_a?(String)
      @nickname = value
      @url = "http://#{nickname}.deviantart.com"
    else
      raise ArgumentError
    end
  end
  
  # Fetches and parses data populating profile_data hash.
  #
  # It returns the time elapsed (calling total_time method).
  def get_data
    if @nickname && @url
      @page = fetch_url(@url)
      @parse_time = parse_profile_page
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
  
  # Parses profile page and populates profile_data.
  def parse_profile_page
    start = Time.now
    
    #img avatar path
    @profile_data[:avatar_path] = @page.search('img.avatar').first.attributes['src']

    # dev info
    info = @page.search('#deviant-info li')
    @profile_data[:status] = info[0].inner_text[8..info[0].inner_text.size] # Toglie 'Status: ' da davanti
    @profile_data[:deviant_type] = info[1].inner_text
    @profile_data[:sex], @profile_data[:location] = info[2].inner_text.strip.split('/')
    @profile_data[:online_status] = info[3].inner_text
    @profile_data[:deviant_since] = info[4].inner_text[14..info[4].inner_text.size]
    @profile_data[:subscribed_since] = info[5].inner_text[17..info[5].inner_text.size] if info[5]

    # dev stats
    stats = @page.search('#deviant-stats li')
    if stats.any?
      stats.each do |item|
        text = item.inner_text
        if text.include?('Scrap')
          @profile_data[:scraps_count] = text[0..(text.size - 18)].gsub(',','').to_i  # Toglie '  Scraps [browse]' dalla fine
        elsif text.include?('Deviation Comment')
          @profile_data[:made_comments_count] = text[0..(text.size - 21)].gsub(',','').to_i # Toglie '  Deviation Comments' dalla fine
        elsif text.include?('Deviant Comment')
          @profile_data[:got_comments_count] = text[0..(text.size - 19)].gsub(',','').to_i  # Toglie '  Deviant Comments' dalla fine
        elsif text.include?('Forum Post')
          @profile_data[:forum_posts_count] = text[0..(text.size - 14)].gsub(',','').to_i # Toglie '  Forum Posts' dalla fine
        elsif text.include?('News Comment')
          @profile_data[:news_comments_count] = text[0..(text.size - 16)].gsub(',','').to_i # Toglie '  News Comment' dalla fine
        elsif text.include?('Deviation')
          @profile_data[:deviations_count] = text[0..(text.size - 12)].gsub(',','').to_i  # Toglie ' deviantions' dalla fine
        elsif text.include?('Pageview')
          @profile_data[:pageviews_count] = text[0..(text.size - 12)].gsub(',','').to_i  # Toglie '  Pageviews' dalla fine
        else
          # Unexpected item in 'deviant-stats'
        end
      end
    end
    
    # devious info box
    info = @page.search('#deviant-infobox.box ul.f li')
    if info.any?
      info.each do |i|
        text = i.inner_text
        if text.include?('Website')
          @profile_data[:user_website] = text[8..text.size]  # Toglie 'Website ' da davanti
        elsif text.include?('Email')
          @profile_data[:user_email] = text[6..text.size]  # Toglie 'Email ' da davanti
        elsif text.include?('AIM')
          @profile_data[:user_aim] = text[4..text.size]  # Toglie 'AIM ' da davanti
        elsif text.include?('MSN')
          @profile_data[:user_msn] = text[4..text.size]  # Toglie 'MSN ' da davanti
        elsif text.include?('Yahoo')
          @profile_data[:user_yahoo] = text[6..text.size]  # Toglie 'Yahoo ' da davanti
        elsif text.include?('ICQ')
          @profile_data[:user_icq] = text[4..text.size]  # Toglie 'ICQ ' da davanti
        elsif text.include?('Skype')
          @profile_data[:user_skype] = text[6..text.size]  # Toglie 'Skype ' da davanti
        elsif text.include?('Age')
          @profile_data[:user_age] = text[13..text.size]
        elsif text.include?('Residence')
          @profile_data[:user_residence] = text[19..text.size]
        elsif text.include?('deviantWEAR')
          @profile_data[:fav_deviantWEAR_size] = text[31..text.size]
        elsif text.include?('Print')
          @profile_data[:fav_print_size] = text[18..text.size]
        elsif text.include?('Interest')
          @profile_data[:interests] = text[11..text.size]
        elsif text.include?('movie')
          @profile_data[:fav_movies] = text[17..text.size]
        elsif text.include?('band')
          @profile_data[:fav_bands] = text[28..text.size]
        elsif text.include?('of music')
          @profile_data[:fav_musics] = text[26..text.size]
        elsif text.include?('artist')
          @profile_data[:fav_artists] = text[18..text.size]
        elsif text.include?('poet')
          @profile_data[:fav_poet_writer] = text[26..text.size]
        elsif text.include?('photographer')
          @profile_data[:fav_photographers] = text[24..text.size]
        elsif text.include?('digital art')
          @profile_data[:fav_style] = text[32..text.size]
        elsif text.include?('Operating')
          @profile_data[:fav_os] = text[18..text.size]
        elsif text.include?('MP3')
          @profile_data[:fav_mp3_players] = text[22..text.size]
        elsif text.include?('Shell')
          @profile_data[:fav_shells] = text[17..text.size]
        elsif text.include?('Wallpaper')
          @profile_data[:fav_wallpapers] = text[21..text.size]
        elsif text.include?('Skin')
          @profile_data[:fav_skins] = text[16..text.size]
        elsif text.include?('game')
          @profile_data[:fav_games] = text[16..text.size]
        elsif text.include?('gaming platform')
          @profile_data[:fav_game_platforms] = text[27..text.size]
        elsif text.include?('cartoon character')
          @profile_data[:fav_cartoon_character] = text[29..text.size]
        elsif text.include?('Quote')
          @profile_data[:pers_quote] = text[16..text.size]
        elsif text.include?('the Trade')
          @profile_data[:tools] = text[20..text.size]
        else
          # Unexpected item in 'deviant-infobox'
        end
      end
    end
    Time.now - start
  end
end