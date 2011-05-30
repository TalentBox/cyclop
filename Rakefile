require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/clean'

# Original Author: Ryan Tomayko
# Copied from https://github.com/rtomayko/rocco/blob/master/Rakefile
begin
  require 'rocco/tasks'
  Rocco::make 'docs/'

  desc "Build Cyclop Docs"
  task :docs => :rocco
  
  desc 'Build docs and open in browser for the reading'
  task :read => :docs do
    sh 'open docs/lib/cyclop.html'
  end
  
  # Make index.html meta redirect to lib/cyclop.html
  file 'docs/index.html' do |f|
    sh %Q{echo '<html><head><meta http-equiv="refresh" content="1;url=http://talentbox.github.com/cyclop/lib/cyclop.html"></head><body></body></html>' > docs/index.html}
  end
  task :docs => 'docs/index.html'
  CLEAN.include 'docs/index.html'

  # GITHUB PAGES ===============================================================
  desc 'Update gh-pages branch'
  task :pages => ['docs/.git', :docs] do
    rev = `git rev-parse --short HEAD`.strip
    Dir.chdir 'docs' do
      sh "git add *.html"
      sh "git add lib/*.html"
      sh "git add lib/cyclop/*.html"
      sh "git commit -m 'rebuild pages from #{rev}'" do |ok,res|
        if ok
          verbose { puts "gh-pages updated" }
          sh "git push -q o HEAD:gh-pages"
        end
      end
    end
  end

  # Update the pages/ directory clone
  file 'docs/.git' => ['docs/', '.git/refs/heads/gh-pages'] do |f|
    sh "cd docs && git init -q && git remote add o ../.git" if !File.exist?(f.name)
    sh "cd docs && git fetch -q o && git reset -q --hard o/gh-pages && touch ."
  end
  CLOBBER.include 'docs/.git'
rescue LoadError
  warn "#$! -- rocco tasks not loaded."
  task :rocco
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

task :default => :spec