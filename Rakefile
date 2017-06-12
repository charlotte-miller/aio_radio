require 'rake'
require 'open-uri'
require 'nokogiri'
require 'phantomjs'
require 'oj'
require 'pry'

namespace :update do
  desc "Update Episode Data"
  task :episodes do
    puts Oj.dump(DataBridge.get_episodes)
  end
end


class DataBridge

  def self.get_episodes
    domain = 'http://www.focusonthefamily.com'
    page = Nokogiri::HTML(open(domain + '/media/adventures-in-odyssey'))
    episodes = page.css('#latest-episode, .past_episodes--item.ng-scope')[0...2] #FIXME
    episodes.collect do |episode|
      page_link = episode.css('.latest_episode--title_link, .past_episode--href')[0]['href'].strip
      media_link = Phantomjs.run('./phantomjs_config.js', (domain + page_link) )# { |line| puts line }
      `open #{media_link}`
      {
        title: episode.css('.latest_episode--title, .past_episode--title').text.strip,
        link:  page_link,
        media: media_link,
        date: episode.css('.latest_episode--air_date, .past_episode--air_date').text.gsub(/^\D*/,'')
      }
    end
  end
end
