# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'English'

Gem::Specification.new do |spec|
  spec.name          = 'cookbook-release'
  spec.version       = '1.7.0'
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
  # TODO: support Chef 17 and leverage knife gem at some point
  spec.add_dependency 'chef', '>= 12.18.31', '< 17.0' # knife code has been moved to dedicated gem starting with Chef 17
  spec.add_dependency 'git-ng' # see https://github.com/schacon/ruby-git/issues/307
  spec.add_dependency 'unicode-emoji'


  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'webmock'
end
