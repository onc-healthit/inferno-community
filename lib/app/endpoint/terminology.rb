# frozen_string_literal: true

require_relative '../utils/terminology'

module Inferno
  class App
    class Terminology < Endpoint
      set :prefix, '/fhir'
      Inferno::Terminology.load_valuesets_from_directory('resources', true)

      get '/ValueSet/?:id_param?/$validate-code', provides: ['application/fhir+json', 'application/fhir+xml'] do
        # Get a valueset, in one of the many ways a valueset can be specified
        valueset_response = get_valueset(params)
        return [400, { 'Content-Type' => 'application/fhir+json' }, valueset_response.to_json] if valueset_response.is_a? FHIR::OperationOutcome

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
          return [400, { 'Content-Type' => 'application/fhir+json' }, FHIR::OperationOutcome.new(issue: issue).to_json]
        end

        code_valid = validate_code(valueset_response, coding, display)

        return_params = if code_valid
                          FHIR::Parameters.new(parameter: [FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: true)])
                        else
                          message = "The code '#{coding[:code]}' is not valid in the valueset '#{valueset_response.valueset_model.id}'"
                          params = [
                            FHIR::Parameters::Parameter.new(name: 'result', valueBoolean: false),
                            FHIR::Parameters::Parameter.new(name: 'cause', valueString: 'invalid'),
                            FHIR::Parameters::Parameter.new(name: 'message', valueString: message)
                          ]
                          FHIR::Parameters.new(parameter: params)
                        end
        return [200, { 'Content-Type' => 'application/fhir+json' }, return_params.to_json]
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
    end
  end
end
