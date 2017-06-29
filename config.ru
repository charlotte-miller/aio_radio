require './config/env'
require './server'
require 'rack/favicon'

use Rack::Favicon, image: "./favicon.ico"
use Rack::ShowExceptions if dev?
run Server.new
