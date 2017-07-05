require './config/env'

class User
  attr_reader :cache_key, :episodes_cache, :new_user

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
      .map {|ep| OpenStruct.new(ep)}
    @new_user ||= self.data.empty?
  end

  def current_episode
    episodes_cache.find {|ep| ep.id==current_episode_id} \
    || episodes_cache.first
  end

  def random_episode
    (episodes_cache - [current_episode]).sample
  end

  def next_episode
    traverse_episode_list(1)
  end

  def next_episode!
    update_user_record({
      current_episode_id: next_episode.id,
      current_offset: 0
    })
    current_episode
  end

  def prev_episode
    traverse_episode_list(-1)
  end

  def prev_episode!
    update_user_record({
      current_episode_id: prev_episode.id,
      current_offset: 0
    })
    current_episode
  end

  def remaining_episode_count
    current_index = episodes_cache.index current_episode
    episodes_cache.length - 1 - current_index
  end

  def current_episode_id; data[:current_episode_id].to_i ;end
  def current_episode_id=(val)
    update_user_record(current_episode_id:val)
  end

  def current_offset; (data[:current_offset] || 0).to_i ;end
  def current_offset=(val)
    update_user_record(current_offset:val)
  end

  def looping?
    !!data[:looping]
  end

  def loop!(is=true)
    update_user_record(looping:is)
  end

  def update_user_record(overrides = {})
    updates = data.merge overrides
    return if data == updates
    updates.merge! updated_at:Date.today.to_s
    LOGGER.info updates
    CACHE.set(cache_key, Oj.dump(updates), 432000) #5.days
  end

  def reset!
    CACHE.set(cache_key, '{}', 432000)
  end

  def data
    Oj.load( CACHE.get(cache_key) || '{}' )
  end

private

  def traverse_episode_list(direction=1) #-1
    episode_ids = episodes_cache.map(&:id)
    current_index = episode_ids.index current_episode_id
    return false unless (0...episode_ids.length).include? current_index + direction
    episodes_cache[current_index+direction]
  end
end
