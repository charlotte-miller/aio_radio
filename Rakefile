require './adapters/episode'
require 'rake'

namespace :radio do
  desc "Update Episode Data"
  task :update do
    Episode.update_radio
    `afplay /System/Library/Sounds/Glass.aiff` if dev?
  end

  desc "Reset CACHE"
  task :reset => [:clear, :update]
  task(:clear) { CACHE.set('episodes', '[]') }
end

namespace :alexa do
end
