ruby '2.4.0'
source 'https://rubygems.org'

gem 'rack'
gem 'rack-reverse-proxy'
gem 'rack-cors'
gem 'rack-ssl'
gem 'puma'
gem 'kgio'
gem 'connection_pool'
gem 'dalli'

gem 'rake',          require: false
gem 'oj',            require: false
gem 'nokogiri',      require: false
gem 'phantomjs',     require: false  #PLUS a buildpack for Heroku: https://github.com/stomita/heroku-buildpack-phantomjs
gem 'alexa_rubykit', require: false,  git:'https://github.com/chip-miller/alexa-rubykit.git'

group 'development' do
  gem 'thin'
  gem 'pry'
  gem 'rspec'
end
