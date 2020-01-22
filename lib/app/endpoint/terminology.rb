# frozen_string_literal: true

require_relative '../utils/terminology'
require 'sinatra/custom_logger'

module Inferno
  class App
    class Terminology < Endpoint
      set :prefix, '/fhir'
      Inferno::Terminology.register_umls_db('umls.db')
      Inferno::Terminology.load_valuesets_from_directory('resources', true)
      set :logger, Logger.new('terminology_misses.log')

      get '/metadata', provides: ['application/fhir+json', 'application/fhir+xml'] do
        if params[:mode] == 'terminology'
          capability = FHIR::TerminologyCapabilities.new
          capability.id = 'InfernoFHIRServer'
          capability.url = "#{request.base_url}#{Inferno::BASE_PATH}/fhir/metadata?mode=terminology"
          capability.description = 'TerminologyCapability resource for the Inferno terminology endpoint'
          capability.date = Time.now.utc.iso8601
          capability.status = 'active'
          loaded_code_systems = Inferno::Terminology.loaded_code_systems
          capability.codeSystem = loaded_code_systems.map { |sys| FHIR::TerminologyCapabilities::CodeSystem.new(uri: sys) }
        else
          capability = FHIR::CapabilityStatement.new
          capability.id = 'InfernoFHIRServer'
          capability.url = "#{request.base_url}#{Inferno::BASE_PATH}/fhir/metadata"
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
            ],
            operation: [
              FHIR::CapabilityStatement::Rest::Resource::Operation.new(
                name: 'validate-code',
                definition: 'http://hl7.org/fhir/OperationDefinition/Resource-validate'
              )
            ]
          )
          capability.format = ['xml', 'json']
        end
        respond_with_type(capability, request.accept, 200)
      end

      get '/ValueSet/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        valueset_validates_code
      rescue StandardError => e
        issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'structure', details: { text: e.message })
        return respond_with_type(FHIR::OperationOutcome.new(issue: issue), request.accept, 400)
      end

      post '/ValueSet/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        body = request.body.read
        parsed_body = FHIR.from_contents(body)
        valueset_validates_code(parsed_body, params[:id_param])
      rescue StandardError => e
        issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'structure', details: { text: e.message })
        return respond_with_type(FHIR::OperationOutcome.new(issue: issue), request.accept, 400)
      end

      get '/CodeSystem/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        codesystem_validates_code(nil, parameters[:id_param])
      end

      post '/CodeSystem/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        body = request.body.read
        parsed_body = FHIR.from_contents(body)
        codesystem_validates_code(parsed_body, params[:id_param])
      rescue StandardError => e
        issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'structure', details: { text: e.message })
        return respond_with_type(FHIR::OperationOutcome.new(issue: issue), request.accept, 400)
      end

      def valueset_validates_code(parameters, id_param = nil)
        # Get a valueset, in one of the many ways a valueset can be specified
        coding = normalize_valueset_coding(parameters)
        valueset_response = get_valueset(id_param, find_param(parameters, 'url'))
        return respond_with_type(valueset_response, request.accept, 400) if valueset_response.is_a? FHIR::OperationOutcome

        validation_fn = FHIR::StructureDefinition.vs_validators[valueset_response]

        if validation_fn
          code_valid = validation_fn.call(coding)
          return_params = if code_valid
                            FHIR::Parameters.new(parameter: [FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: true)])
                          else
                            message = "The code '#{coding['code']}' from the code system '#{coding['system']}' is not valid in the valueset '#{valueset_response}'"
                            params = [
                              FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: false),
                              FHIR::Parameters::Parameter.new(name: 'cause', valueString: 'invalid'),
                              FHIR::Parameters::Parameter.new(name: 'message', valueString: message)
                            ]
                            FHIR::Parameters.new(parameter: params)
                          end
          return respond_with_type(return_params, request.accept, 200)
        else
          issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'required', details: { text: 'The specified code system is not known by the terminology server' })
          logger.warn "Need code system #{coding['system']}"
          return respond_with_type(FHIR::OperationOutcome.new(issue: issue), request.accept, 400)
        end
      end

      def find_param(parameters, name)
        parameters.parameter.detect { |param| param.name == name }&.value
      end

      def normalize_valueset_coding(parameters)
        if find_param(parameters, 'coding')
          find_param(parameters, 'coding').to_hash
        elsif find_param(parameters, 'system') && find_param(parameters, 'code')
          { 'code' => find_param(parameters, 'code'), 'system' => find_param(parameters, 'system') }
        else
          {}
        end
      end

      def normalize_codesystem_coding(parameters, system_param = nil)
        if find_param(parameters, 'coding')
          find_param(parameters, 'coding').to_hash
        elsif (find_param(parameters, 'url') || system_param) && find_param(parameters, 'code')
          system_param ||= find_param(parameters, 'url')
          { 'code' => find_param(parameters, 'code'), 'system' => system_param }
        else
          {}
        end
      end

      def codesystem_validates_code(parameters, id_param)
        coding = normalize_codesystem_coding(parameters, id_param)
        validation_fn = FHIR::StructureDefinition.vs_validators[coding['system']]
        if validation_fn
          retval = if validation_fn.call(coding)
                     FHIR::Parameters.new(parameter: [FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: true)])
                   else
                     message = "The code '#{coding['code']}' is not a valid member of '#{coding['system']}'"
                     params = [
                       FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: false),
                       FHIR::Parameters::Parameter.new(name: 'cause', valueString: 'invalid'),
                       FHIR::Parameters::Parameter.new(name: 'message', valueString: message)
                     ]
                     FHIR::Parameters.new(parameter: params)
                   end
          respond_with_type(retval, request.accept, 200)
        else
          issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'required', details: { text: 'The specified code system is not known by the terminology server' })
          logger.warn "Need code system #{coding['system']}"
          return respond_with_type(FHIR::OperationOutcome.new(issue: issue), request.accept, 400)
        end
      end

      private

      def validate_code(valueset, coding, _display)
        valueset.contains_code?(coding)
        # TODO: Figure out how to validate displays, seeing as we don't have access to displays in the valueset object
      end

      def get_valueset(id_param, url_param)
        # if this param is present, the operation was called on a particular ValueSet instance
        if id_param && !id_param.empty?
          begin
            valueset = Inferno::Terminology.get_valueset_by_id(params[:id_param])
          rescue Inferno::Terminology::UnknownValueSetException
            error_code = { code: 'MSG_NO_MATCH', display: "No ValueSet found matching the id '#{pid_param}''" }
            logger.warn "Need Valueset #{id_param}"
            issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'value', details: { coding: error_code })
            return FHIR::OperationOutcome.new(issue: issue)
          end
        elsif url_param && !url_param.empty?
          begin
            valueset = Inferno::Terminology.get_valueset(url_param)
          rescue Inferno::Terminology::UnknownValueSetException
            error_code = { code: 'MSG_NO_MATCH', display: "No ValueSet found matching the URL '#{url_param}''" }
            logger.warn "Need Valueset #{url_param}"
            issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'value', details: { coding: error_code })
            return FHIR::OperationOutcome.new(issue: issue)
          end
        elsif params[:context]
          # TODO: implement me
        else
          issue_text = 'No parameter that identifies the terminology/Valueset to validate against was supplied'
          issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'required', details: { text: issue_text })
          return FHIR::OperationOutcome.new(issue: issue)
        end
        valueset.url
      end

      def respond_with_type(resource, accept, status = 200)
        accept.each do |type|
          case type.to_s
          when %r{application\/.*json}
            return [status, { 'Content-Type' => 'application/fhir+json' }, resource.to_json]
          when %r{application\/.*xml}
            return [status, { 'Content-Type' => 'application/fhir+xml' }, resource.to_xml]
          else
            return [status, { 'Content-Type' => 'application/fhir+json' }, resource.to_json]
          end
        end
      end
    end
  end
end
