# frozen_string_literal: true

require_relative '../utils/terminology'

module Inferno
  class App
    class Terminology < Endpoint
      set :prefix, '/fhir'
      Inferno::Terminology.register_umls_db('umls.db')
      Inferno::Terminology.load_valuesets_from_directory('resources', true)

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
        begin
          valueset_validates_code
        rescue => e
          binding.pry
          # TODO: Return an error if the validates code op fails
        end
      end

      post '/ValueSet/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        begin
          valueset_validates_code
        rescue => e
          binding.pry
          # TODO: Return an error if the validates code op fails
        end
      end

      get '/CodeSystem/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        codesystem_validates_code
      end

      post '/CodeSystem/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        begin
          parsed_body = FHIR.from_contents(request.body.read)
          codesystem_validates_code(parsed_body)
        rescue => exception
          binding.pry
          # TODO: Return an error if the validates code op fails
        end
      end

      def valueset_validates_code
        # Get a valueset, in one of the many ways a valueset can be specified
        valueset_response = get_valueset(params)
        return respond_with_type(valueset_response, request.accept, 400) if valueset_response.is_a? FHIR::OperationOutcome

        # now that we have a valueset, let's get the code to validate against it
        if params[:code]
          coding = { code: params[:code], system: params[:system] }
          display = params[:display]
        elsif params[:coding]
          coding = { code: params[:coding][:code], system: params[:coding][:system] }
          display = params[:coding][:display]
        elsif params[:codeableconcept]
          # TODO: handle this later, because you could have to validate multiple codes...
        else
          issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'required', details: { text: 'No code parameters were specified to be validated' })
          return respond_with_type(FHIR::OperationOutcome.new(issue: issue), request.accept, 400)
        end

        code_valid = validate_code(valueset_response, coding, display)

        return_params = if code_valid
                          FHIR::Parameters.new(parameter: [FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: true)])
                        else
                          message = "The code '#{coding[:code]}' from the code system '#{coding[:system]}' is not valid in the valueset '#{valueset_response.valueset_model.id}'"
                          params = [
                            FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: false),
                            FHIR::Parameters::Parameter.new(name: 'cause', valueString: 'invalid'),
                            FHIR::Parameters::Parameter.new(name: 'message', valueString: message)
                          ]
                          FHIR::Parameters.new(parameter: params)
                        end
        respond_with_type(return_params, request.accept, 200)
      end

      def codesystem_validates_code(parameters)
        # TODO: Implement me
      end

      private

      def validate_code(valueset, coding, _display)
        valueset.contains_code?(coding)
        # TODO: Figure out how to validate displays, seeing as we don't have access to displays in the valueset object
      end

      def get_valueset(params)
        # if this param is present, the operation was called on a particular ValueSet instance
        if params[:id_param] && !params[:id_param].empty?
          begin
            valueset = Inferno::Terminology.get_valueset_by_id(params[:id_param])
          rescue Inferno::Terminology::UnknownValueSetException
            error_code = { code: 'MSG_NO_MATCH', display: "No ValueSet found matching the id '#{params[:id_param]}''" }
            issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'value', details: { coding: error_code })
            return FHIR::OperationOutcome.new(issue: issue)
          end
        elsif params[:url]
          begin
            valueset = Inferno::Terminology.get_valueset(params[:url])
          rescue Inferno::Terminology::UnknownValueSetException
            error_code = { code: 'MSG_NO_MATCH', display: "No ValueSet found matching the URL '#{params[:url]}''" }
            issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'value', details: { coding: error_code })
            return FHIR::OperationOutcome.new(issue: issue)
          end
        elsif params[:context]
          # TODO: implement me
        else
          issue = FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'required', details: { text: 'No parameter that identifies the terminology/Valueset to validate against was supplied' })
          return FHIR::OperationOutcome.new(issue: issue)
        end
        valueset.process_valueset
        valueset
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
