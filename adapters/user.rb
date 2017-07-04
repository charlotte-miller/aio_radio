require './config/env'

class User
  attr_reader :cache_key, :episodes_cache

  def self.from_request_obj(input_obj)
    me = new(input_obj.session.user_id)
    player = input_obj.json.dig('context', 'AudioPlayer')
    player && me.update_user_record({
      current_offset: (player['offsetInMilliseconds'] || 0),
      current_episode_id: (player['token']||'').gsub(/\D/,'')
    })
    return me
  end

  def self.from_player_callback(post_body)
    me = new(post_body.dig('context','System','user','userId'))
    player = post_body.dig('context', 'AudioPlayer')
    player && me.update_user_record({
      current_offset: (player['offsetInMilliseconds'] || 0),
      current_episode_id: player['token'].gsub(/\D/,'')
    })
    return me
  end

  def initialize(amazon_userId)
    @cache_key = "user_#{amazon_userId}"
    @episodes_cache = Oj.load( CACHE.get('episodes') || '[]')
  end

  def current_episode_id; data[:current_episode_id] ;end
  def current_episode_id=(val)
    update_user_record(current_episode_id:val)
  end

  def current_offset; data[:current_offset] ;end
  def current_offset=(val)
    update_user_record(current_offset:val)
  end

  def update_user_record(overrides = {})
    updates = data.merge overrides
    return if data == updates
    LOGGER.info updates
    CACHE.set(cache_key, Oj.dump(updates))
  end

  def current_episode
    OpenStruct.new(
      episodes_cache.find {|ep| ep[:id]==current_episode_id} \
      || episodes_cache.first
    )
  end

  private
    def data
      Oj.load( CACHE.get(cache_key) || '{}' )
    end
end
