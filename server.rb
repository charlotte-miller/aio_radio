require 'rack'
require './config/memcached'

class Server
  def call(env)
    [200, {"Content-Type" => "text/json"}, [CACHE.get('episodes') || '[]']] #
  end
end
