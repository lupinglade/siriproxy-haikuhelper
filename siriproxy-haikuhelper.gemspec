# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "siriproxy-haikuhelper"
  s.version     = "0.2.0" 
  s.authors     = ["lupinglade"]
  s.email       = [""]
  s.homepage    = ""
  s.summary     = %q{A HaikuHelper Home Automation Siri Proxy Plugin}
  s.description = %q{Lets you control your HAI home automation system via HaikuHelper}

  s.rubyforge_project = "siriproxy-haikuhelper"

  s.files         = `git ls-files 2> /dev/null`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/* 2> /dev/null`.split("\n")
  s.executables   = `git ls-files -- bin/* 2> /dev/null`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "httparty"
end
