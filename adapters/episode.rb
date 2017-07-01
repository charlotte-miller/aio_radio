require './config/logger'    #LOGGER
require './config/memcached' #CACHE
require './config/env'
require 'open-uri'
require 'nokogiri'
require 'phantomjs'
require 'oj'
require 'pry' if development?

class Episode
  def self.update_radio
    current_episodes = new.get_episodes
    if current_episodes.length >=6
      CACHE.set 'episodes', Oj.dump(current_episodes)
    else
      LOGGER.warn "NO UPDATES"
    end
  end

  def initialize
    @domain = 'http://www.focusonthefamily.com'
    @current_cache =  Oj.load(CACHE.get 'episodes')
    @currently_cached_ids = @current_cache.map {|ep| ep[:id]}
  end

  def get_episodes
    episodes_index_page = Nokogiri::HTML(open(@domain + '/media/adventures-in-odyssey'))
      .css('#latest-episode, .past_episodes--item.hide-js')
    episodes_index_page.collect do |episode|
      episode_page_link = @domain + episode
        .css('.latest_episode--title_link, .past_episode--href')
        .first.attr('href').strip

      ep_title = episode.css('.latest_episode--title, .past_episode--title').text.strip
      ep_id = (ep_title =~ /(\d+)\:/) && $1.to_i
      if @currently_cached_ids.include?(ep_id)
        @currently_cached_ids.delete(:ep_id)
        LOGGER.info "CACHE #{ep_title}"
        next @current_cache.find {|ep| ep[:id]==ep_id}
      end

      ep_store_link = Nokogiri::HTML(open(episode_page_link)).at('a:contains("purchase the download")')
      ep_store_link &&= ep_store_link.attr('href').strip
      ep_store_link &&= ep_store_link.sub(/#[^#]*$/,'')
      ep_store_link || next #
      LOGGER.info "UPDATING #{ep_title}"

      ep_image_link = Nokogiri::HTML(open(ep_store_link))
        .css('img#image-main')
        .first.attr('src').strip

      ep_media_link = nil
      Phantomjs.run('./adapters/video_player.js', episode_page_link, current_environment ) { |line| ep_media_link = line.strip }
      puts ep_media_link if dev?

      ep_air_date = episode
        .css('.latest_episode--air_date, .past_episode--air_date')
        .text.gsub(/^\D*/,'')
      ep_air_date &&= Date.strptime(ep_air_date, "%m/%d/%Y").to_s
      {
        id:    ep_id,
        title: ep_title,
        link:  ep_store_link,
        media: ep_media_link,
        image: ep_image_link,
        air_date: ep_air_date
      }
    end.compact
  end
end
