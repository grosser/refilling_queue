name = "refilling_queue"
require "./lib/#{name}/version"

Gem::Specification.new name, RefillingQueue::VERSION do |s|
  s.summary = "A queue that refreshes itself when it gets empty or stale, so you can keep popping"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'

  s.add_development_dependency 'redis'
  s.add_development_dependency 'wwtd'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~>2'
end
