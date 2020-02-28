# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cyclop/version"

Gem::Specification.new do |s|
  s.name        = "cyclop"
  s.version     = Cyclop::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joseph HALTER", "Jonathan TRON"]
  s.email       = ["joseph.halter@thetalentbox.com", "jonathan.tron@thetalentbox.com"]
  s.homepage    = "https://github.com/TalentBox/cyclop"
  s.summary     = "Job queue with MongoDB"
  s.description = "Job queue with MongoDB with emphasis on never losing any task even if worker fails hard (segfault)."
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("bson_ext", ["~> 1.3"])
  s.add_runtime_dependency("mongo", ["~> 1.3"])
  s.add_runtime_dependency("posix-spawn", ["~> 0.3.6"])

  s.add_development_dependency("rake", "~> 13.0.1")
  s.add_development_dependency("rspec", ["~> 2.6.0"])
  s.add_development_dependency("rocco", ["~> 0.7"])
end
