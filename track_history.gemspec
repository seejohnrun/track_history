require 'lib/track_history'

spec = Gem::Specification.new do |s|
  
  s.name = 'track_history'
  s.author = 'John Crepezzi'
  s.add_development_dependency('rspec')
  s.description = 'Smart, performant model auditing'
  s.email = 'john.crepezzi@patch.com'
  s.files = Dir['lib/**/*.rb']
  s.has_rdoc = true
  s.homepage = 'http://github.com/seejohnrun/historical'
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.summary = 'Smart model auditing'
  s.test_files = Dir.glob('spec/*.rb')
  s.version = TrackHistory::VERSION
  s.rubyforge_project = "historical"

end
