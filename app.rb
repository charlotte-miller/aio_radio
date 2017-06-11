require 'rack'

class App
  def call(env)
    [200, {"Content-Type" => "text/json"}, 'memcached data']
  end
  

end