# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'English'

Gem::Specification.new do |spec|
  spec.name          = 'cookbook-release'
  spec.version       = '0.4.3'
  spec.authors       = ['Grégoire Seux']
  spec.email         = 'g.seux@criteo.com'
  spec.summary       = 'Provide primitives (and rake tasks) to release a cookbook'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/criteo/cookbook-release.git'
  spec.license       = 'Apache License v2'

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'semantic'
  spec.add_dependency 'highline'
  spec.add_dependency 'mixlib-shellout'
  spec.add_dependency 'chef'


  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'webmock'
end
