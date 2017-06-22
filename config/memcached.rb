require 'kgio'
require 'connection_pool'
require 'dalli'

CACHE = Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "localhost:11211").split(","),
                    {:username => ENV["MEMCACHIER_USERNAME"],
                     :password => ENV["MEMCACHIER_PASSWORD"],
                     :failover => true,
                     :socket_timeout => 1.5,
                     :socket_failure_delay => 0.2,
                     :pool_size => Integer(ENV['RAILS_MAX_THREADS'] || 5),
                    })
