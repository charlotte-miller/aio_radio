require 'rack'
require 'dalli'
require './config/memcached'

class App
  def call(env)
    CACHE.set 'episodes', 'RADIO!'
    [200, {"Content-Type" => "text/json"}, CACHE.get('episodes')]
  end


end
