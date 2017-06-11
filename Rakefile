require 'rake'
require 'open-uri'
require 'nokogiri'
require 'watir'
require 'phantomjs'
require 'oj'
require 'pry'

namespace :update do
  desc "Update Episode Data"
  task :episodes do
    Oj.dump(DataBridge.new.get_episodes)
  end
end


class DataBridge
  def initialize
    @domain = 'http://www.focusonthefamily.com'
    @capabilities = Selenium::WebDriver::Remote::Capabilities.phantomjs(
      driver_path: Phantomjs.path,
      "phantomjs.page.settings.userAgent" => "Chrome",
      "phantomjs.page.settings.loadImages" => false,
    )
    @driver = Selenium::WebDriver.for :phantomjs, :desired_capabilities => @capabilities
    
    # Phantomjs.run('./phantomjs_config.js') { |line| puts line }
   
    @browser = ::Watir::Browser.new @driver
    @browser.execute_script('
      var create = document.createElement;
      document.createElement = function (tag) {
        var elem = create.call(document, tag);
        if (tag === "video") {
          elem.canPlayType = function () { return "probably" };
        }
        return elem;
      };
    ')
  end
  
  def get_episodes
    page = Nokogiri::HTML(open(@domain + '/media/adventures-in-odyssey'))
    episodes = page.css('#latest-episode, .past_episodes--item.ng-scope')[0...2]
    episodes.collect do |episode|
      page_link = episode.css('.latest_episode--title_link, .past_episode--href')[0]['href'].strip
      {
        title: episode.css('.latest_episode--title, .past_episode--title').text.strip,
        link:  page_link,
        media: get_media_link(page_link),
        date: episode.css('.latest_episode--air_date, .past_episode--air_date').text.gsub(/^\D*/,'')
      }
    end
  end

  def get_media_link(page_link)    
    @browser.goto(@domain + page_link )
    @browser.video(class: "video", wait_until_present:3) 
    @driver.save_screenshot('click.png')
    page = Nokogiri::HTML(@browser.html) #@driver.page_source
    binding.pry
    page.css('#mediaplayer .video')[0]['src'] rescue `open click.png`
  end
end