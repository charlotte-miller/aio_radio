require './app'
require 'rack/favicon'

use Rack::ShowExceptions
use Rack::Favicon, image: "./favicon.ico"
run App.new
