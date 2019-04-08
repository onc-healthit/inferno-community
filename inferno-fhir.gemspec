# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = 'inferno-fhir'
  spec.version       = Inferno::VERSION
  spec.authors       = ['Rob Scanlon', 'Reece Adamson', 'Chase Zhou']
  spec.email         = ['rscanlon@mitre.org']

  spec.summary       = %q{Inferno}
  spec.description   = %q{Inferno}
  spec.homepage      = 'https://github.com/siteadmin/inferno'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'thin'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'sinatra-contrib'
  spec.add_dependency 'addressable'
  spec.add_dependency 'fhir_client', '~> 3.0'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'time_difference'
  spec.add_dependency 'pry'
  spec.add_dependency 'rb-readline'
  spec.add_dependency 'data_mapper'
  spec.add_dependency 'dm-sqlite-adapter'
  spec.add_dependency 'base62-rb'
  spec.add_dependency 'rake'
  spec.add_dependency 'webmock'
  spec.add_dependency 'rack-test'
  spec.add_dependency 'json-jwt'
  spec.add_dependency 'colorize'
  spec.add_dependency 'kramdown'
  spec.add_dependency 'selenium-webdriver'
  spec.add_dependency 'rubocop'
  spec.add_dependency 'bloomer'
  spec.add_dependency 'sqlite3'

  # spec.add_dependency 'activesupport', '>= 3'
  # spec.add_dependency 'addressable', '>= 2.3'
  # spec.add_dependency 'fhir_models', '>= 3.0.3'
  # spec.add_dependency 'fhir_dstu2_models', '>= 1.0.4'
  # spec.add_dependency 'nokogiri', '>= 1.8.2'
  # spec.add_dependency 'oauth2', '~> 1.1'
  # spec.add_dependency 'rack', '>= 1.5'
  # spec.add_dependency 'rest-client', '~> 2.0'
  # spec.add_dependency 'tilt', '>= 1.1'

  # spec.add_development_dependency 'bundler', '~> 2.0'
  # spec.add_development_dependency 'rake', '~> 10.0'
  # spec.add_development_dependency 'pry'
  # spec.add_development_dependency 'webmock'
  # spec.add_development_dependency 'test-unit'
  # spec.add_development_dependency 'simplecov'
end
