# frozen_string_literal: true

require 'sinatra/json'
require_relative 'fhir_definitions'

module Inferno
  class App
    class Endpoint
      class FhirApi < Endpoint
        include Inferno::FhirResourceDefinitions

        set :prefix, '/fhir'

        before do
          headers 'Content-Type' => 'application/fhir+json'
        end

        # Get Capability Statement
        get '/metadata' do
          capability_statement_resource.to_json
        end

        # Get Bundle of OperationDefinitions
        get '/OperationDefinition' do
          operation_definition = operation_definition_execute_resource
          entry = resource_to_entry(operation_definition)
          entries_to_bundle('OperationDefinition_all', [entry]).to_json
        end

        # Get OperationDefinition by id to resource
        get '/OperationDefinition/:_id' do
          operation_definition = operation_definition_execute_resource
          if params[:_id] == operation_definition.id
            operation_definition.to_json
          else
            not_found_operation_outcome('OperationDefinition', 'id', params[:_id]).to_json
          end
        end

        # Get Bundle of StructureDefinitions
        get '/StructureDefinition' do
          structure_definitions = all_structure_definition_names.map { |struct| send(struct) }
          entries = structure_definitions.map { |struct| resource_to_entry(struct) }
          entries_to_bundle('StructureDefinition_all', entries).to_json
        end

        # Get StructureDefinitions by id to resource
        get '/StructureDefinition/:_id' do
          if all_structure_definition_names.include? params[:_id]
            send(params[:_id]).to_json
          else
            not_found_operation_outcome('StructureDefinition', 'id', params[:_id]).to_json
          end
        end

        # Get Bundle of SearchParameters
        get '/SearchParameter' do
          search_parameters = all_search_parameter_names.map { |search| send(search) }
          entries = search_parameters.map { |search| resource_to_entry(search) }
          entries_to_bundle('SearchParameter_all', entries).to_json
        end

        # Get SearchParameter by id to resource
        get '/SearchParameter/:_id' do
          if all_search_parameter_names.include? params[:_id]
            send(params[:_id]).to_json
          else
            not_found_operation_outcome('SearchParameter', 'id', params[:_id]).to_json
          end
        end

        # Get Bundle of TestScripts
        get '/TestScript' do
          if params[:_id].present?          # Search TestScripts by id
            testscript_by_id(params[:_id]).to_json
          elsif params[:module].present?    # Search TestScripts by module
            testscript_by_module(params[:module]).to_json
          else                              # Return all TestScripts
            testscript_all.to_json
          end
        end

        # Get TestScript by id to resource
        get '/TestScript/:_id' do
          testscript = find_testscript_by_id(params[:_id])
          testscript.present? ? testscript.to_json : not_found_operation_outcome('TestScript', 'id', params[:_id]).to_json
        end

        # Create instance given parameters, run TestScript by id, return TestReport as parameter
        post '/TestScript/:_id/$execute' do
          sequence_class = find_sequence_by_id(params[:_id])
          halt 404, "Unknown sequence: #{params[:_id]}" if sequence_class.nil?

          # Get parameters by URL or by JSON Parameter resource
          parameters = params.length <= 1 ? parameters_to_hash : params
          verified = parameters[:test_instance].present? || (parameters[:fhir_server].present? && parameters[:module].present?)
          halt 404, 'Missing parameter: Please input either (a) test_instance or (b) fhir_server and module (optional client_id, client_secret).' unless verified

          # Setup of operation: create/reuse test instance
          if parameters[:test_instance].nil?
            instance_result = 'pass'
            instance = create_instance(parameters)
          else
            instance_result = 'skip'
            instance = Inferno::Models::TestingInstance.get(parameters[:test_instance])
            halt 404, "Unknown test_instance: #{parameters[:test_instance]}" if instance.nil?
          end

          # Run sequence
          sequence = sequence_class_to_sequence(sequence_class, instance)
          sequence_result = sequence.start

          testreport = results_to_testreport(sequence_class, sequence_result, instance_result)
          testreport.to_json
        end

        # Get Bundle of TestReports
        get '/TestReport' do
          if params[:_id].present?                  # Search TestReports by id
            testreport_by_id(params[:_id]).to_json
          elsif params[:test_instance].present?     # Search TestReports by test instance
            testreport_by_test_instance(params[:test_instance]).to_json
          else                                      # Return all TestReports
            testreport_all.to_json
          end
        end

        # Get TestReport by id to resource
        get '/TestReport/:_id' do
          sequence_result = Inferno::Models::SequenceResult.get(params[:_id])
          if sequence_result.nil?
            testreport = not_found_operation_outcome('TestReport', 'id', params[:_id])
          else
            sequence = find_sequence_by_id(sequence_result.name)
            testreport = results_to_testreport(sequence, sequence_result, 'skip')
          end
          testreport.to_json
        end

        # ----------------------------------------------------------------------------------------------

        def all_structure_definition_names
          ['structure_definition_test_instance', 'structure_definition_module', 'structure_definition_client_state']
        end

        def all_search_parameter_names
          ['search_parameter_id', 'search_parameter_module', 'search_parameter_test_instance']
        end

        def testscript_all
          all_sequences = available_sequences
          all_testscripts = all_sequences.map { |seq| sequence_to_testscript(seq) }
          all_entries = all_testscripts.map { |script| resource_to_entry(script) }
          entries_to_bundle('TestScript_all', all_entries)
        end

        def testscript_by_id(id)
          testscript = find_testscript_by_id(id)
          if testscript.present?
            testscript_entry = resource_to_entry(testscript)
            entries_to_bundle("TestScript_#{id}", [testscript_entry])
          else
            operation_outcome = not_found_operation_outcome('TestScript', 'id', id)
            not_found_bundle(operation_outcome)
          end
        end

        def testscript_by_module(mod)
          if available_modules.include? mod
            module_sequences = sequences_by_module[mod]
            testscripts = module_sequences.map { |seq| sequence_to_testscript(seq) }
            entries = testscripts.map { |script| resource_to_entry(script) }
            entries_to_bundle("TestScript_#{mod}", entries)
          else
            operation_outcome = not_found_operation_outcome('TestScript', 'module', mod)
            not_found_bundle(operation_outcome)
          end
        end

        # Remove eventually for security
        def testreport_all
          sequence_results = Inferno::Models::SequenceResult

          # Only get the first four sequence results for runtime (will be removed later anyway)
          all_testreports = sequence_results[0..3].map { |result| results_to_testreport(find_sequence_by_id(result.name), result, 'skip') }

          all_entries = all_testreports.map { |report| resource_to_entry(report) }
          entries_to_bundle('TestReport_all', all_entries)
        end

        def testreport_by_id(id)
          sequence_result = Inferno::Models::SequenceResult.get(id)
          if sequence_result.nil?
            operation_outcome = not_found_operation_outcome('TestReport', 'id', id)
            not_found_bundle(operation_outcome)
          else
            sequence = find_sequence_by_id(sequence_result.name)
            testreport = results_to_testreport(sequence, sequence_result, 'skip')
            testreport_entry = resource_to_entry(testreport)
            entries_to_bundle("TestReport_#{id}", [testreport_entry])
          end
        end

        def testreport_by_test_instance(test_instance)
          instance = Inferno::Models::TestingInstance.get(test_instance)
          if instance.nil?
            operation_outcome = not_found_operation_outcome('TestReport', 'test_instance', test_instance)
            not_found_bundle(operation_outcome)
          else
            all_results = instance.latest_results
            all_testreports = all_results.map { |result| results_to_testreport(find_sequence_by_id(result[0]), result[1], 'skip') }
            all_entries = all_testreports.map { |report| resource_to_entry(report) }
            entries_to_bundle("TestReport_all_#{test_instance}", all_entries)
          end
        end

        # Convert inputted Parameter JSON resource into hash for execute operation
        def parameters_to_hash
          request.body.rewind
          data = request.body.read
          parameters_resource = FHIR.from_contents(data) if data.present?

          parameters = {}
          operation = operation_definition_execute_resource

          operation.parameter.each do |input|
            next unless input.use == 'in'

            parameter = parameters_resource&.parameter&.find { |param| param.name == input.name }
            type = 'value' + input.type[0].capitalize + input.type[1..-1]
            parameters[input.name.to_sym] = parameter&.send(type)
          end

          parameters[:_id] = params[:_id]
          parameters
        end

        def sequence_class_to_sequence(sequence_class, instance)
          client = FHIR::Client.new(instance.url)
          case instance.fhir_version
          when 'stu3'
            client.use_stu3
          when 'dstu2'
            client.use_dstu2
          else
            client.use_r4
          end
          client.default_json

          sequence_class.new(instance, client, settings.disable_tls_tests)
        end

        def create_instance(parameters)
          fhir_server = parameters[:fhir_server]&.chomp('/')
          inferno_module = Inferno::Module.get(parameters[:module])
          halt 404, "Unknown module: #{parameters[:module]}" if inferno_module.nil?

          instance = Inferno::Models::TestingInstance.new(url: fhir_server,
                                                          name: 'instance_name',
                                                          base_url: request.base_url,
                                                          selected_module: inferno_module.name)

          instance.client_endpoint_key = parameters[:client_endpoint_key].nil? ? 'static' : parameters[:client_endpoint_key]
          instance.client_id = parameters[:client_id] unless parameters[:client_id].nil?
          instance.client_secret = parameters[:client_secret] unless parameters[:client_secret].nil?
          instance.initiate_login_uri = "#{request.base_url}#{base_path}/oauth2/#{instance.client_endpoint_key}/launch"
          instance.redirect_uris = "#{request.base_url}#{base_path}/oauth2/#{instance.client_endpoint_key}/redirect"
          instance.save!

          instance
        end

        def available_modules
          available_modules = Inferno::Module.available_modules
          available_modules.map { |mod| mod[0] }
        end

        def available_sequences
          all_sequences = []
          module_names = available_modules
          module_names.each { |mod| all_sequences << Inferno::Module.get(mod).sequences }
          all_sequences.flatten.uniq
        end

        def find_sequence_by_id(id)
          Inferno::Sequence::SequenceBase.descendants.find { |seq| seq.sequence_name == id }
        end

        def find_testscript_by_id(id)
          sequence = find_sequence_by_id(id)
          sequence.present? ? sequence_to_testscript(sequence) : nil
        end

        # Return a hash of the sequences in each module
        def sequences_by_module
          sequences_by_mod = {}
          available_modules = Inferno::Module.available_modules
          available_modules.each do |mod|
            mod[1].test_sets.each do |test_set|
              test_set[1].groups.each do |group|
                group.test_cases.each do |test_case|
                  sequences_by_mod[mod[0]] = [] if sequences_by_mod[mod[0]].nil?
                  sequences_by_mod[mod[0]] << test_case.sequence
                end
              end
            end
          end
          sequences_by_mod
        end

        # Find which modules a sequence belongs to
        def find_modules(sequence)
          modules = []
          sequences_by_mod = sequences_by_module
          sequences_by_mod.each do |mod_name, mod_list|
            modules << mod_name if mod_list.include? sequence
          end
          modules
        end
      end
    end
  end
end
