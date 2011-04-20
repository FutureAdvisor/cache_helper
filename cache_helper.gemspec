# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cache_helper/version"

Gem::Specification.new do |s|
  s.name        = "cache_helper"
  s.version     = CacheHelper::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Clyde Law"]
  s.email       = ["clyde@futureadvisor.com"]
  s.homepage    = %q{http://github.com/FutureAdvisor/cache_helper}
  s.summary     = %q{Adds methods to more easily work with Rails caching.}
  s.description = %q{Overrides ActiveRecord::Base#cache_key to return unique keys for new records and adds methods to more easily work with Rails caching.}
  s.license     = 'MIT'

  s.add_dependency('activerecord', '>= 2.1.0')
  s.add_dependency('alias_helper')

  s.rubyforge_project = "cache_helper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
