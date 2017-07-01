require './config/memcached'
require 'alexa_rubykit'
require 'oj'

class AIORadioSkill
  attr_reader :input, :output, :response, :episode_cache_hash

  def initialize(post_body)
    raise ArgumentError.new("Post Body must be valid JSON") if post_body == ''
    @input = AlexaRubykit.build_request(Oj.load(post_body))
    @output = AlexaRubykit::Response.new
    @episode_cache_hash = Oj.load CACHE.get('episodes')
  end

  def build_response
    case input.type
    when "LAUNCH_REQUEST"
      play_latest
    when "INTENT_REQUEST"
      case input.name
        when "EpisodeTitle" then read_title
        when "PlayLatest"   then play_episode
        when "PlayDate"     then play_episode input.slots["AMAZON.DATE"]["value"]
      end
    when "SESSION_ENDED_REQUEST"
      # it's over
    end

    @response = output.build_response(session_end = true) #returns json
  end

private

  def read_title
    # TODO, currently playing
    output.add_speech episode_cache_hash.first[:title]
  end

  def play_episode(air_date=:current)
    air_date = (Date.parse(air_date) - 1).to_s
    episode_cache_hash_item = echi = \
      (air_date == :current && episode_cache_hash.first) \
      || episode_cache_hash.find {|ep| ep[:air_date]==air_date} \
      || episode_cache_hash.first

    output.add_session_attribute :current_episode_id, episode_cache_hash_item[:id]
    output.add_audio_url echi[:media], "episode-#{echi[:id]}"
    episode_num, title = episode_cache_hash_item[:title].split(":")
    output.add_hash_card( {
      :type => "Standard",
      :title => echi[:title].sub('Episode ',''),
      :text => "Find more episodes online!", #"\n\n#{echi[:link]}",
      :image => {
        :smallImageUrl => echi[:image],
        :largeImageUrl => echi[:image]
      }
    })
  end
end
