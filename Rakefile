require 'rspec/core/rake_task'
require File.dirname(__FILE__) + '/lib/track_history/version'
 
task :build => :test do
  system "gem build track_history.gemspec"
end

task :release => :build do
  # tag and push
  system "git tag v#{TrackHistory::VERSION}"
  system "git push origin --tags"
  # push the gem
  system "gem push track_history-#{TrackHistory::VERSION}.gem"
end
 
RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  fail_on_error = true # be explicit
end
 
RSpec::Core::RakeTask.new(:rcov) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  fail_on_error = true # be explicit
end
