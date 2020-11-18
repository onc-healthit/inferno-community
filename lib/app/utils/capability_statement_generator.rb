# frozen_string_literal: true

require_relative '../utils/terminology'

module Inferno
  module CapabilityStatementGenerator
    def self.terminology_capabilities(base_url)
      capability = FHIR::TerminologyCapabilities.new
      capability.id = 'InfernoFHIRServer'
      capability.url = "#{base_url}#{Inferno::BASE_PATH}/fhir/metadata?mode=terminology"
      capability.description = 'TerminologyCapability resource for the Inferno terminology endpoint'
      capability.date = Time.now.utc.iso8601
      capability.status = 'active'
      loaded_code_systems = Inferno::Terminology.loaded_code_systems
      capability.codeSystem = loaded_code_systems.map { |sys| FHIR::TerminologyCapabilities::CodeSystem.new(uri: sys) }
      capability
    end

    def self.capability_statement(base_url)
      capability = FHIR::CapabilityStatement.new
      capability.id = 'InfernoFHIRServer'
      capability.url = "#{base_url}#{Inferno::BASE_PATH}/fhir/metadata"
      capability.description = 'CapabilityStatement resource for the Inferno terminology endpoint'
      capability.date = Time.now.utc.iso8601
      capability.kind = 'instance'
      capability.status = 'active'
      capability.fhirVersion = '4.0.1'
      capability.rest = FHIR::CapabilityStatement::Rest.new(
        mode: 'server',
        resource: [
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'ValueSet',
            operation: [
              FHIR::CapabilityStatement::Rest::Resource::Operation.new(
                name: 'validate-code',
                definition: 'http://hl7.org/fhir/OperationDefinition/ValueSet-validate-code'
              )
            ]
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'CodeSystem',
            operation: [
              FHIR::CapabilityStatement::Rest::Resource::Operation.new(
                name: 'validate-code',
                definition: 'http://hl7.org/fhir/OperationDefinition/CodeSystem-validate-code'
              )
            ]
          )
        ]
      )
      capability.format = ['xml', 'json']
      capability
    end
  end
end
