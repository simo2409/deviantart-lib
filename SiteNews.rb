# Author::    Simone Dall'Angelo (simone@wonsys.net), Michele Finotto (michele@wonsys.net), Matteo Nodari (matteo@wonsys.net)
# Copyright:: Copyright (c) 2008 Wonsys S.r.l.
# License::   BSD License

require File.join(File.dirname(__FILE__), 'Page.rb')

# == Introduction
# This class fetches and parse DeviantART's News page(s).
#
# It uses http://today.deviantart.com/dds/ as url.
#
# It can use many pages, urls available are:
# - http://news.deviantart.com/browse/front/
# - http://news.deviantart.com/browse/art_news/
# - http://news.deviantart.com/browse/culture/
# - http://news.deviantart.com/browse/deviantart_inc/
# - http://news.deviantart.com/browse/fun/
#
# Note: All urls are encoded in the class and is not possible to change them.
#
# == Use
# To use SiteNews you have simply to create a new instance of SiteNews. Something like that:
#
#   empty_instance_of_site_news = SiteNews.new
#
# To populate site_news you have to call get-data method:
#
#   data = empty_instance_of_site_news.get_data
#
# You can also specify if you want that the parsing has to start immediately after the initialization:
#
#   instance_of_site_news-filled_with_parsed_data = Sitenews.new('front', true)
#
# The first parameter identifies the section that you want to fetch and parse, choices available are:
# - front   -> http://news.deviantart.com/browse/front/
# - art     -> http://news.deviantart.com/browse/art_news/
# - culture -> http://news.deviantart.com/browse/culture/
# - da      -> http://news.deviantart.com/browse/deviantart_inc/
# - fun     -> http://news.deviantart.com/browse/fun/

class SiteNews < Page
  # Page's url to fetch (set at inizialization).
  attr_reader :url
  
  # It contains all parsed data.
  attr_reader :news_data
  
  # it contains the raw page (parsed by hpricot)
  attr_reader :page
  
  # Inizializes url using correct path.
  #
  # Data argument identifies the news section to fetch.
  #
  # Data values:
  # - 'front' (default): 'All topic' section.
  # - 'art': 'Art News' section.
  # - 'culture': 'Culture' section.
  # - 'da': 'deviantART, Inc' section.
  # - 'fun': 'Fun' section.
  #
  # If parse_now is set to true the method fetches and parses data.
  #
  # It returns SiteNews instance.
  #
  # Note: if parse_now is set to true it sets total_time too.
  def initialize(data = 'front', parse_now = false)
    @parse_time = nil
    @news_data = Array.new
    @url_prepend = "http://news.deviantart.com"
    @url = "#{@url_prepend}#{set_url(data)}"
    if parse_now
      @page = fetch_url(@url)
      @parse_time = parse_news_page
      @page = nil # To flush @page content and free memory
    end
  end
  
  # Fetchs and parse data populating @news_data hash.
  #
  # Data argument identifies the news section to fetch.
  #
  # Data values:
  # - 'front' (default): 'All topic' section.
  # - 'art': 'Art News' section.
  # - 'culture': 'Culture' section.
  # - 'da': 'deviantART, Inc' section.
  # - 'fun': 'Fun' section.
  # It returns time elapsed (calling total_time method).
  def get_data(data = 'front')
    if @url
      @url = "#{@url_prepend}#{set_url(data)}"
      @page = fetch_url(@url)
      @parse_time = parse_news_page
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
  
  # Parses news page and populates news_data.
  def parse_news_page
    start = Time.now
    entries = @page.search('#news-main .iconleft .report')
    if entries.any?
      entries.each do |entry|
        @news_data << {:love => entry.search('.love span').inner_text, :title => entry.search('h2').inner_text, :author => entry.search('.line0 small a .u').inner_text, :summary => entry.search('.text').inner_text.strip}
      end
    end
    Time.now - start
  end
  
  # It returns the last part of url, url_prepend + this_method = url to fetch
  def set_url(data)
    case data
    when 'art': '/browse/art_news/'
    when 'culture': '/browse/culture/'
    when 'da': '/browse/deviantart_inc/'
    when 'fun': '/browse/fun/'
    else
      '/browse/front/'
    end
  end
end