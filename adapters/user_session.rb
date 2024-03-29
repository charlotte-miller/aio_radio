require './config/env'

class UserSession
  attr_reader :cache_key, :new_user, :post_body_hash

  def initialize(post_body)
    @post_body_hash = post_body.is_a?(Hash) ? post_body : Oj.load(post_body)
    raise ArgumentError.new('amazon_user_id required') unless amazon_user_id
    @cache_key = "user_#{amazon_user_id}"
    @new_user ||= data.empty?
    advance_stale_episode
    update_player_data
  end

  def current_episode
    found = episodes_cache.find {|ep| ep.id==current_episode_id}
    found ||= self.current_episode = episodes_cache.first
    found
  end

  def current_episode=(episode)
    episode = episodes_cache.first if episode.is_a? FalseClass
    episode_id = episode           if episode.is_a? Integer
    episode_id = episode.to_i      if episode.is_a? String
    episode_id = episode.id        if episode.is_a? OpenStruct
    episode_id = episode[:id]      if episode.is_a? Hash
    raise ArgumentError.new('current_episode argument not supported') unless episode_id.is_a? Integer

    update_user_record({
      current_episode_id: episode_id,
      current_offset: 0
    })
    current_episode
  end

  def random_episode; (episodes_cache - [current_episode]).sample ;end

  def next_episode  ;traverse_episode_list(1)           ;end
  def prev_episode  ;traverse_episode_list(-1)          ;end                                                   ;

  def next_episode! ;self.current_episode= next_episode ;end
  def prev_episode! ;self.current_episode= prev_episode ;end

  def remaining_episode_count
    current_index = episodes_cache.index current_episode
    episodes_cache.length - 1 - current_index
  end

  def current_episode_id; (data[:current_episode_id]).to_i  ;end
  def current_offset;     (data[:current_offset] || 0).to_i ;end
  def updated_at;         (data[:updated_at] && Date.parse(data[:updated_at])) ;end

  def current_offset=(offsetInMilliseconds)
    update_user_record(current_offset:offsetInMilliseconds)
  end

  def looping?
    !!data[:looping]
  end

  def loop!(is=true)
    update_user_record(looping:is)
  end

  def reset!
    @data = nil
    CACHE.set(cache_key, '{}', 432000)
  end

  def episodes_cache
    @episodes_cache ||= CACHE.episodes.map {|ep| OpenStruct.new(ep)}
  end


private

  def data
    @data ||= Oj.load( CACHE.get(cache_key) || '{}' )
  end

  def update_user_record(overrides = {})
    updates = data.merge overrides
    return if data == updates
    updates.merge! updated_at:local_today.to_s
    LOGGER.info updates
    @data = nil
    CACHE.set(cache_key, Oj.dump(updates), 604800) #7.days
  end

  def traverse_episode_list(direction=1) #-1
    episode_ids = episodes_cache.map(&:id)
    current_index = episode_ids.index current_episode_id
    return false unless current_index && (0...episode_ids.length).include?( current_index + direction )
    episodes_cache[current_index+direction]
  end

  def local_today
    (DateTime.now - (7/24.0)).to_date
  end

  def amazon_user_id
    unless post_body_hash['session'].nil?
      post_body_hash.dig('session', 'user','userId')
    else
      post_body_hash.dig('context','System','user','userId')
    end
  end

  def advance_stale_episode
    if updated_at && updated_at < local_today
      unless current_offset == 0
        next_episode!
      end
    end
  end

  def update_player_data
    player = post_body_hash.dig('context', 'AudioPlayer')
    if player && player['token']
      proposed_offset, proposed_episode_id = [
        (player['offsetInMilliseconds'].to_i || 0),
        player['token'].gsub(/\D/,'').to_i
      ]
    end

    same_episode = current_episode_id == proposed_episode_id
    same_offset =  current_offset == proposed_offset

    unless same_episode && same_offset
      unless same_episode
        self.current_episode= proposed_episode_id
      else
        self.current_offset= proposed_offset
      end
    end
  end
end
