require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rocco/tasks'
  Rocco::make 'docs/'

  desc "Build Rocco Docs"
  task :docs => :rocco
  
  desc 'Build docs and open in browser for the reading'
  task :read => :docs do
    sh 'open docs/lib/cyclop.html'
  end
rescue LoadError
  warn "#$! -- rocco tasks not loaded."
  task :rocco
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

task :default => :spec