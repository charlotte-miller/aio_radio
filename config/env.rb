require './config/logger'    #LOGGER
require './config/memcached' #CACHE

def current_environment
  ENV['RACK_ENV'] || 'development'
end

def dev?
  current_environment != 'production'
end
alias :development? :dev?

def env_domain
  if dev?
    'http://localhost:9292'
  else
    'https://aio-radio.herokuapp.com'
  end
end

require 'pry' if development?
