require 'rack'
require './config/memcached'

class App
  def call(env)
    CACHE.get('episodes') || CACHE.set('episodes', "HELLO RADIO")
    [200, {"Content-Type" => "text/json"}, [CACHE.get('episodes')]] #
  end


end
