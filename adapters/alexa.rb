require './config/memcached'
require './config/logger'
require './config/env'
require './adapters/user'
require 'alexa_rubykit'

class OdysseyRadioSkillController
  attr_reader :input, :output, :response, :episodes_cache, :user

  def initialize(post_body)
    raise ArgumentError.new("Post Body must be valid JSON") if post_body == ''
    post_body = Oj.load(post_body) if post_body.is_a? String

    if AlexaRubykit.valid_alexa? post_body
      @input = AlexaRubykit.build_request(post_body)
      @user = User.from_request_obj(input)
    else
      @input ||= OpenStruct.new(type:post_body.dig('request','type'))
      @user = User.from_player_callback(post_body)
    end

    @output = AlexaRubykit::Response.new
    @episodes_cache = Oj.load( CACHE.get('episodes') )
      .map {|ep| OpenStruct.new(ep)}
  end

  def build_response
    case input.type
    when "LAUNCH_REQUEST"
      play_episode
    when "INTENT_REQUEST"
      LOGGER.info input.name
      case input.name
        when /^AMAZON/      then handle_amazon
        when "EpisodeTitle" then read_title
        when "PlayLatest"   then play_episode
        when "PlayDate"     then play_episode input.slots["AMAZON.DATE"]["value"]
      end
    when /^AudioPlayer/ then LOGGER.info input.type
    when "SESSION_ENDED_REQUEST"
      # it's over
    end

    @response = output.build_response(session_end = true) #returns json
  end

private

  def handle_amazon
    case input.name
      when /^AMAZON\.(Pause|Stop)Intent/ then
        output.add_audio_stop
      when 'AMAZON.CancelIntent' then
        output.add_audio_stop
        user.current_offset=0 #FIXME currently gets overwritten by the ResumeIntent
      when 'AMAZON.ResumeIntent' then
        play_episode user.current_episode.id, user.current_offset
      when 'AMAZON.StartOverIntent' then
        play_episode user.current_episode.id, 0
        # play_episode episodes_cache.first.id, 0
      when 'AMAZON.HelpIntent' then
        read_help
      when 'AMAZON.NextIntent' then
        if user.next_episode
          play_episode user.next_episode.id
        else
          output.add_speech "There are no more episodes. Check back tomorrow."
        end
      when 'AMAZON.PreviousIntent' then
        if user.prev_episode
          play_episode user.prev_episode.id
        else
          output.add_speech "That's as far back as I can go."
        end
    end
  end

  def read_title
    output.add_speech user.current_episode.title
  end

  def read_help
    output.add_speech "Help comming soon for: "
    output.add_speech user.current_episode.title
  end

  # accepts episode_id, air_date, nil (for current_episode)
  def play_episode(air_date=nil, offsetInMilliseconds=0)
    (air_date = (Date.parse(air_date) - 1).to_s) if air_date.is_a? String
    (air_date = episodes_cache.find {|ep| ep.id==air_date}[:air_date]) if air_date.is_a? Integer

    episodes_cache_item = eci = \
      episodes_cache.find {|ep| ep.air_date==air_date} \
      || episodes_cache.first

    user.current_episode_id= eci.id
    output.add_audio_url eci.media, "episode-#{eci.id}", (offsetInMilliseconds || 0)
    output.add_hash_card( {
      :type => "Standard",
      :title => eci.title.sub('Episode ',''),
      :text => "Find more episodes online!", #"\n\n#{eci[:link]}",
      :image => {
        :smallImageUrl => eci.image,
        :largeImageUrl => eci.image
      }
    })
  end
end
