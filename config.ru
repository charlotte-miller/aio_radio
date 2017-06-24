require './config/env'
require './server'
require 'rack/favicon'

use Rack::ShowExceptions if dev?
use Rack::Favicon, image: "./favicon.ico"
run Server.new
