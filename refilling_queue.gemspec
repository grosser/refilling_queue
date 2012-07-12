$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
name = "refilling_queue"
require "#{name}/version"

Gem::Specification.new name, RefillingQueue::VERSION do |s|
  s.summary = "A queue that refreshes itself when it gets empty or stale, so you can keep popping"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'
end
