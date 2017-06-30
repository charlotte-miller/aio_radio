require 'rack'
require './config/memcached'
require './adapters/alexa'

class Server
  def call(env)
    begin
      post_body = env['rack.input'].read
      skill = AIORadioSkill.new(post_body)
      reply = skill.build_response
    rescue => e
      reply = Oj.dump([
        error: e.message,
        # backtrace: e.backtrace,
        data: Oj.load( CACHE.get('episodes') || '[]'),
      ])
    end
    [200, {"Content-Type" => "text/json"}, [reply]] #
  end
end
