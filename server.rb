require 'rack'
require './config/env'
require './config/memcached'
require './adapters/alexa'

class Server
  def call(env)
    begin
      post_body = env['rack.input'].read
      skill = OdysseyRadioSkillController.new(post_body)
      reply = skill.respond
    rescue => e
      raise e if dev?
      reply = Oj.dump([
        error: e.message,
        # backtrace: e.backtrace,
        data: Oj.load( CACHE.get('episodes') || '[]'),
      ])
    end
    [200, {"Content-Type" => "text/json"}, [reply]] #
  end
end
