# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'inferno/version'

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
  spec.add_runtime_dependency 'data_mapper', '~> 1.2.0'
  spec.add_runtime_dependency 'json-jwt', '~> 1.11.0'
  spec.add_runtime_dependency 'kramdown', '~> 2.1.0'
  spec.add_runtime_dependency 'selenium-webdriver', '~> 3.142.6'
  spec.add_runtime_dependency 'sqlite3', '~> 1.4.1'
  spec.add_runtime_dependency 'bloomer', '~> 1.0.0'
  spec.add_runtime_dependency 'base62-rb', '~> 0.3.1'
  spec.add_runtime_dependency 'dm-sqlite-adapter', '~> 1.2.0'
  spec.add_runtime_dependency 'thin', '~> 1.7.2'

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.77'
end
