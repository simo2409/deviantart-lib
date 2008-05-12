# Author::    Simone Dall'Angelo (simone@wonsys.net), Michele Finotto (michele@wonsys.net), Matteo Nodari (matteo@wonsys.net)
# Copyright:: Copyright (c) 2008 Wonsys S.r.l.
# License::   BSD License

require 'rubygems'
require 'hpricot'
require 'open-uri'

# == Introduction
# This class is used by others of deviantART-lib to fetch pages.
#
# When a page is fetched it populates @fetch_time with time elapsed to fetch page and it returns the page fetched.

class Page
  def initialize
    @fetch_time = nil
  end
  # Fetches a page.
  #
  # It fetches the url passed as argument, sets @fetch_time and returns page.
  #
  # Possible failures:
  # - If URL validation fails it raises an InvalidURL exception.
  # - If it's unable to connect (dns or connection problem) it raises an UnableToConnect exception.
  def fetch_url(url)
    if validate(url)
      data = connect(url)
      start = Time.now
      page = Hpricot(data)
      @fetch_time = Time.now - start
      page
    end
  end
  
  private
  
  # Validates url passed as argument to verify that it's a valid url.
  #
  # If it is not a valid url it raises an InvalidURL exception.
  def validate(url)
    if url && url.is_a?(String) && url.match(/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix)
      return true
    else
      raise InvalidURL
    end
  end
  
  # Connects to url passed as argument.
  #
  # If it can't connect it raises an UnableToConnect exception.
  def connect(url)
    begin
      content = open(url)
    rescue
      raise UnableToConnect
    end
  end
end

# Custom exceptions
class InvalidURL < ArgumentError
end
class UnableToConnect < ArgumentError
end