# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'poirot_rails/version'

Gem::Specification.new do |gem|
  gem.name          = "poirot_rails"
  gem.version       = PoirotRails::VERSION
  gem.authors       = ["Gustavo Giráldez"]
  gem.email         = ["ggiraldez@manas.com.ar"]
  gem.description   = %q{}
  gem.summary       = %q{}
  gem.homepage      = "https://bitbucket.org/instedd/poirot_rails"

  gem.add_dependency 'rails', '>= 3.2'
  gem.add_dependency 'zmq'
  gem.add_dependency 'guid'
  gem.add_dependency 'json'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
