require './config/env'
require 'rack/favicon'
require 'rack/cors'
require 'rack/reverse_proxy'
require './server'

use Rack::ShowExceptions if dev?

use Rack::Cors do
  allow do
    origins '*' #http://ask-ifr-download.s3.amazonaws.com
    resource '/media/*', :headers => :any, :methods => :get
  end
end

use Rack::ReverseProxy do
  # Forward the path /test* to http://example.com/test*
  reverse_proxy '/media', 'https://store.focusonthefamily.com/'

  # Forward the path /foo/* to http://example.com/bar/*
  # reverse_proxy /^\/foo(\/.*)$/, 'http://example.com/bar$1', username: 'name', password: 'basic_auth_secret'
end

use Rack::Favicon, image: "./favicon.ico"
# use Rack::Static, :urls => ["/images"]
run Server.new
