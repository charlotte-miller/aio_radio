require 'kgio'
require 'connection_pool'
require 'dalli'
require 'date'
require 'oj'


CACHE ||= Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "localhost:11211").split(","),
                    {:username => ENV["MEMCACHIER_USERNAME"],
                     :password => ENV["MEMCACHIER_PASSWORD"],
                     :failover => true,
                     :socket_timeout => 1.5,
                     :socket_failure_delay => 0.2,
                     :pool_size => Integer(ENV['RAILS_MAX_THREADS'] || 5),
                    })

class << CACHE
  def episodes
    Oj.load( CACHE.get('episodes') || '[]')
  end

  def episodes=(current_episodes)
    CACHE.set 'episodes', Oj.dump(current_episodes)
  end
end