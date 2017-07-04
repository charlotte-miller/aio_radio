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
    @episodes_cache = Oj.load( CACHE.get('episodes') || '[]' )
      .map {|ep| OpenStruct.new(ep)}
  end

  def respond
    case input.type
    when "LAUNCH_REQUEST"
      if user.new_user
        output.add_speech "Welcome to Odyssey Radio. Check the Alexa app for features, and enjoy the show."
      else
        read_episode_loading
      end
      play_episode
    when "INTENT_REQUEST"
      LOGGER.info input.name
      case input.name
        when /^AMAZON/      then handle_amazon
        when "EpisodeTitle" then read_title
        when "PlayLatest"   then play_episode
        when "ListEpisodes" then list_episodes(:silent)
      end

    when "AudioPlayer.PlaybackNearlyFinished" then
      user.next_episode!

    when /^AudioPlayer/ then LOGGER.info input.type

    when "SESSION_ENDED_REQUEST" then # it's over
    end

    @response = output.build_response(session_end = true) #returns json
  end

private

  def handle_amazon
    case input.name
      when /^AMAZON\.(Cancel|Pause|Stop)Intent/ then
        output.add_audio_stop

      when 'AMAZON.ResumeIntent' then
        play_episode

      when 'AMAZON.StartOverIntent' then
        user.current_offset = 0
        output.add_speech "Restarting the Episode"
        play_episode

      when 'AMAZON.HelpIntent' then
        list_episodes(:silently)
        output.add_speech "Welcome to Odyssey Radio! There are #{episodes_cache.length} episodes to explore. Navigate using 'Next, and Previous'. For more info: Check the Alexa app for a list of today's episodes. New episodes are added daily."

      when 'AMAZON.NextIntent' then
        if user.next_episode
          user.next_episode!
          play_episode
        else
          output.add_speech "There are no more episodes. Check back tomorrow."
        end

      when 'AMAZON.PreviousIntent' then
        if user.prev_episode
          user.prev_episode!
          play_episode
        else
          output.add_speech "That's as far back as I can go."
        end

      when 'AMAZON.LoopOnIntent' then
        #continuous play

      when 'AMAZON.LoopOffIntent' then
        #single episode [default]
    end
  end

  def read_title
    output.add_speech user.current_episode.title
  end


  def read_episode_loading
    action = user.current_offset==0 ? 'Starting' : 'Resuming'
    output.add_speech "#{action} episode"
  end

  def list_episodes(silent=false)
    text = "Alexa, Ask Odyssey Radio to play episode #{user.current_episode_id}\n-\n"+ \
      (episodes_cache.map {|ep| ep.title.gsub!('Episode ',''); ep}
      .map {|ep| ep.title = "- #{ep.title}" ;ep}
      .map {|ep| ep.id != user.current_episode_id ? ep.title : ep.title.gsub!(/^- \d+/, '▸ Playing'); ep}
      .map(&:title)
      .join("\n"))
    output.add_speech("Check the Alexa app for available episodes, or say 'Next' to explore.") unless silent
    output.add_hash_card( {
      :type => "Standard",
      :title => "Episode List",
      :text => text,
      :image => {
        :smallImageUrl => episodes_cache.first.image, #"#{domain}/images/odyssey_logo_720_480.jpg",
        :largeImageUrl => episodes_cache.first.image,
      }
    })
  end

  # accepts episode_id, nil (for current_episode)
  def play_episode(episode_id=nil, offsetInMilliseconds=nil)
    episode_id ||= user.current_episode.id
    offsetInMilliseconds ||= user.current_offset

    eci = episodes_cache.find {|ep| ep.id==episode_id}

    if user.remaining_episode_count > 1
      text = "#{user.remaining_episode_count} NEW Episodes\nSay 'Alexa, Next' to explore.\nOr 'Alexa, Ask Odyssey Radio for an Episode List'"
    elsif user.remaining_episode_count == 1
      text = "1 NEW Episode: #{user.next_episode.title.gsub(/Episode \d+:/,'')}.\n\nSay 'Alexa, Next' to listen"
    else
      text = "No More Episodes.\nSay 'Alexa, Previous' to re-listen to your favorites.\nNEW Episodes Every Week"
    end

    user.current_episode_id= eci.id
    output.add_audio_url eci.media, "episode-#{eci.id}", (offsetInMilliseconds || 0)
    output.add_hash_card( {
      :type => "Standard",
      :title => eci.title.sub('Episode ',''),
      :text => text, #"\n\n#{eci[:link]}",
      :image => {
        :smallImageUrl => eci.image,
        :largeImageUrl => eci.image
      }
    })
  end
end
