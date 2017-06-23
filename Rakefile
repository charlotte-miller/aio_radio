require './config/memcached'
require 'rake'
require 'open-uri'
require 'nokogiri'
require 'phantomjs'
require 'oj'
require 'pry' unless ENV['RACK_ENV']=='production'

desc "Update Episode Data"
task :update_radio do
  DataBridge.set_episodes
end


class DataBridge
  class << self
    def set_episodes
      CACHE.set 'episodes', Oj.dump(get_episodes)
    end

    def get_episodes
      domain = 'http://www.focusonthefamily.com'
      episodes = Nokogiri::HTML(open(domain + '/media/adventures-in-odyssey'))
        .css('#latest-episode, .past_episodes--item.hide-js')[0...7]
      episodes.collect do |episode|
        episode_page_link = domain + episode
          .css('.latest_episode--title_link, .past_episode--href')
          .first.attr('href').strip

        ep_store_link = Nokogiri::HTML(open(episode_page_link))
          .at('a:contains("purchase the download")')
          .attr('href').strip

        ep_image_link = Nokogiri::HTML(open(ep_store_link))
          .css('img#image-main')
          .first.attr('src').strip

        ep_media_link = Phantomjs.run('./phantomjs_config.js', (episode_page_link) )# { |line| puts line }
        puts ep_media_link if dev?

        {
          title: episode.css('.latest_episode--title, .past_episode--title').text.strip,
          link:  ep_store_link,
          media: ep_media_link,
          image: ep_image_link,
          date: episode.css('.latest_episode--air_date, .past_episode--air_date').text.gsub(/^\D*/,'')
        }
      end
    end

    def dev?; ENV['RACK_ENV']=='development' ;end
  end
end
