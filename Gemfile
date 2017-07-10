ruby '2.4.0'
source 'https://rubygems.org'

gem 'rack'
gem 'puma'
gem 'kgio'
gem 'connection_pool'
gem 'dalli'
gem 'rack-reverse-proxy'
gem 'rack-cors'

gem 'rake',          require: false
gem 'oj',            require: false
gem 'nokogiri',      require: false
gem 'phantomjs',     require: false  #PLUS a buildpack for Heroku: https://github.com/stomita/heroku-buildpack-phantomjs
gem 'alexa_rubykit', require: false,  github:'chip-miller/alexa-rubykit'

group 'development' do
  gem 'thin'
  gem 'pry'
  gem 'rspec'
end
