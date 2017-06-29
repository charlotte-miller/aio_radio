require 'rack'
require './config/memcached'
require './adapters/alexa'

class Server
  def call(env)
    post_body = env['rack.input'].read
    skill = AIORadioSkill.new(post_body)
    [200, {"Content-Type" => "text/json"}, [skill.build_response]] #
  end
end
