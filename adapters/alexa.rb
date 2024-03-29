require './config/memcached'
require './config/logger'
require './config/env'
require './adapters/user_session'
require 'alexa_rubykit'

class OdysseyRadioSkillController
  attr_reader :input, :output, :response, :user_session

  def initialize(post_body)
    raise ArgumentError.new("Post Body must be valid JSON") if post_body == ''
    post_body_hash = Oj.load(post_body) if post_body.is_a? String
    @user_session = UserSession.new post_body_hash

    if AlexaRubykit.valid_alexa? post_body_hash
      @input = AlexaRubykit.build_request(post_body_hash)
    else
      @input ||= OpenStruct.new({
        type:  post_body_hash.dig('request','type'),
        error: post_body_hash.dig('request','error')
      })
    end
    @output = AlexaRubykit::Response.new
  end

  def respond
    input_name = input.respond_to?(:name) && input.name
    LOGGER.info input_name || input.type

    case input.type
    when "LAUNCH_REQUEST"
      if user_session.new_user
        output.add_speech "Welcome to Odyssey Radio. Check the Alexa app for features, and enjoy the show."
      else
        read_episode_loading
      end
      play_episode
      add_episode_card

    when "INTENT_REQUEST"
      case input.name
        when /^AMAZON/      then handle_amazon
        when "EpisodeTitle" then read_title
        when "PlayLatest"   then play_episode
        when "ListEpisodes" then
          list_episodes(:silent)
          output.add_speech "Check the Alexa app for a complete episode list."

        when 'PlayById'     then
          play_episode input.slots["episodeId"]["value"].to_i, 0
          list_episodes(:silent) #overrides player card for menu effect
      end

    when "AudioPlayer.PlaybackNearlyFinished" then
      if user_session.looping? && user_session.next_episode
        play_episode user_session.next_episode, 0, {'playBehavior'=> 'REPLACE_ENQUEUED'}
      end

    when "AudioPlayer.PlaybackFinished" then
      user_session.next_episode!

    when 'AudioPlayer.PlaybackFailed' then
      LOGGER.warn "#{input.error['type']} - #{input.error['message']}"

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
        output.add_speech "Restarting the Episode"
        play_episode nil, 0

      when 'AMAZON.HelpIntent' then
        list_episodes(:silently)
        output.add_speech( "Welcome to Odyssey Radio! There are #{user_session.episodes_cache.length} episodes to explore. Navigate using Next and Previous. For more info: Check the Alexa app for a list of today's episodes. New episodes are added daily.")

      when 'AMAZON.NextIntent' then
        if user_session.next_episode
          user_session.next_episode!
          play_episode
          add_episode_card
        else
          output.add_speech "There are no more episodes. Check back tomorrow."
        end

      when 'AMAZON.PreviousIntent' then
        if user_session.prev_episode
          user_session.prev_episode!
          play_episode
          add_episode_card
        else
          output.add_speech "That's as far back as I can go."
        end

      when 'AMAZON.ShuffleOnIntent' then
        random = user_session.random_episode
        output.add_speech "Shuffling Episodes... Playing #{random.title}"
        play_episode random.id, 0
        add_episode_card

      when 'AMAZON.LoopOnIntent' then
        user_session.loop!
        output.add_speech "Continuous play enabled"
        play_episode

      when 'AMAZON.LoopOffIntent' then
        user_session.loop!(false) #single episode [default]
        output.add_speech "Continuous play disabled"

      # Poorly supported
      # when 'AMAZON.RepeatIntent' then
      #   play_episode nil, [(user_session.current_offset-10_000), 0].max.to_i

    end
  end

  def read_title
    output.add_speech user_session.current_episode.title
  end

  def read_episode_loading
    action = user_session.current_offset==0 ? 'Starting' : 'Resuming'
    output.add_speech "#{action} episode"
  end

  def list_episodes(silent=false)
    text = "Choose by Episode Number\nTRY: Alexa, Ask Odyssey to play '#{user_session.random_episode.id}'\n \n"+ \
      (user_session.episodes_cache.map {|ep| ep.title.gsub!('Episode ',''); ep}
      .map {|ep| ep.title = "- #{ep.title}" ;ep}
      .map {|ep| ep.id != user_session.current_episode_id ? ep.title : ep.title.gsub!(/^- \d+/, '▸ Playing'); ep}
      .map(&:title)
      .join("\n")+"\n \nSay 'Alexa Shuffle' for a random episode\nSay 'Alexa Loop (ON | OFF)' for continuous play.")
    output.add_speech("Check the Alexa app for available episodes, or say 'Next' to explore.") unless silent
    output.add_hash_card( {
      :type => "Standard",
      :title => "Episode List",
      :text => text,
      :image => {
        :smallImageUrl => user_session.current_episode.image,
        :largeImageUrl => user_session.current_episode.image
      }
    })
  end

  # accepts episode_obj, episode_id, nil (for current_episode)
  def play_episode(episode=nil, offsetInMilliseconds=nil, options={})
    user_session.current_episode = episode              if episode
    user_session.current_offset  = offsetInMilliseconds if offsetInMilliseconds

    ep_item = user_session.current_episode
    output.add_audio_url ep_item.media, "episode-#{ep_item.id}", user_session.current_offset, options
  end

  def add_episode_card
    ep_item = user_session.current_episode

    if user_session.remaining_episode_count > 1
      text = "#{user_session.remaining_episode_count} NEW Episodes\nSay 'Alexa, Next' to explore.\nOr 'Alexa, open the Odyssey episode list'"
    elsif user_session.remaining_episode_count == 1
      text = "1 NEW Episode: #{user_session.next_episode.title.gsub(/Episode \d+:/,'')}.\n\nSay 'Alexa, Next' to listen"
    else
      text = "Last Episode.\nSay 'Alexa, Previous' to re-listen to your favorites.\nNEW Episodes Every Week"
    end

    output.add_hash_card( {
      :type => "Standard",
      :title => ep_item.title.sub('Episode ',''),
      :text => text, #"\n\n#{ep_item[:link]}",
      :image => {
        :smallImageUrl => ep_item.image,
        :largeImageUrl => ep_item.image
      }
    })
  end
end
