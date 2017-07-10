require './config/env'
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
end

# use Rack::Static, :urls => ["/images"]
run Server.new
