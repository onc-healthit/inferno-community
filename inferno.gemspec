# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = 'inferno'
  spec.version       = Inferno::VERSION
  spec.authors       = ['Rob Scanlon', 'Reece Adamson', 'Steve MacVicar', 'Chase Zhou', 'Yunwei Wang']
  spec.email         = ['inferno@mitre.org']

  spec.summary       = 'Tests for FHIR Servers '
  spec.description   = 'Inferno is a rich and rigorous testing suite for
                        HL7® Fast Healthcare Interoperability Resources (FHIR)
                        to help developers implement the FHIR standard consistently'
  spec.homepage      = 'https://github.com/onc-healthit/inferno'
  spec.license       = 'Apache 2'

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/onc-healthit/inferno'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in
  # the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
        .split("\x0")
        .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sinatra', '~> 2.0.7'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 2.0.7'
  spec.add_runtime_dependency 'fhir_client', '~> 4.0.3'
  spec.add_runtime_dependency 'time_difference', '~> 0.7.0'
  spec.add_runtime_dependency 'pry', '0.12.2'
  spec.add_runtime_dependency 'pry-byebug',


  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.77'
end
