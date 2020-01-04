# frozen_string_literal: true

require 'sinatra/json'

module Inferno
  module FhirResourceDefinitions
    def capability_statement_resource
      FHIR::CapabilityStatement.new(
        id: 'Inferno_testing_server',
        name: 'Inferno Capability Statement',
        status: 'active',
        date: '2019-07',
        kind: 'capability',
        software: {
          name: 'Inferno',
          version: '2.3.1'
        },
        fhirVersion: '4.0.0',
        format: ['json'],
        rest: [
          {
            mode: 'server',
            resource: [
              {
                type: 'TestScript',
                profile: 'https://www.hl7.org/fhir/testscript.html',
                supportedProfile: [
                  'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_module'
                ],
                interaction: [
                  {
                    code: 'read'
                  }
                ],
                searchParam: [
                  {
                    name: '_id',
                    definition: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_id',
                    type: 'string'
                  },
                  {
                    name: 'module',
                    definition: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_module',
                    type: 'string'
                  }
                ],
                operation: [
                  {
                    name: 'Execute TestScript',
                    definition: 'https://inferno.healthit.gov/inferno/fhir/OperationDefinition/operation_definition_execute'
                  }
                ]
              },
              {
                type: 'TestReport',
                profile: 'https://www.hl7.org/fhir/testreport.html',
                supportedProfile: [
                  'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_module',
                  'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_test_instance',
                  'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_client_state'
                ],
                interaction: [
                  {
                    code: 'read'
                  }
                ],
                searchParam: [
                  {
                    name: '_id',
                    definition: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_id',
                    type: 'string'
                  },
                  {
                    name: 'test_instance',
                    definition: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_test_instance',
                    type: 'string'
                  }
                ]
              },
              {
                type: 'OperationDefinition',
                interaction: [
                  {
                    code: 'read'
                  }
                ]
              },
              {
                type: 'StructureDefinition',
                interaction: [
                  {
                    code: 'read'
                  }
                ]
              },
              {
                type: 'SearchParameter',
                interaction: [
                  {
                    code: 'read'
                  }
                ]
              }
            ]
          }
        ]
      )
    end

    def operation_definition_execute_resource
      FHIR::OperationDefinition.new(
        id: 'operation_definition_execute',
        name: 'execute',
        title: 'Execute TestScript',
        status: 'active',
        kind: 'operation',
        description: 'Runs a TestScript on the FHIR server provided in the parameters',
        code: 'execute',
        comment: 'For input parameters, $execute requires (a) a test_instance or (b) a fhir_server, module, '\
                  'and optional client_id and client_secret parameters. The operation will return an error code '\
                  'if the correct parameters are not provided.',
        url: 'https://inferno.healthit.gov/inferno/fhir/OperationDefinition/operation_definition_execute',
        resource: [
          'TestScript'
        ],
        system: 'false',
        type: 'false',
        instance: 'true',
        parameter: [
          {
            name: 'return',
            use: 'out',
            min: 1,
            max: '1',
            documentation: 'The results of the TestScript execution as a TestReport Resource.',
            type: 'TestReport'
          },
          {
            name: '_id',
            use: 'in',
            min: 1,
            max: '1',
            documentation: 'ID that refers to the TestScript to be run.',
            type: 'id'
          },
          {
            name: 'test_instance',
            use: 'in',
            min: 0,
            max: '1',
            documentation: 'Identifier of a previously tested FHIR server, identified by a TestReport. '\
                            'This parameter is required if a fhir_server and module are not provided.',
            type: 'id'
          },
          {
            name: 'fhir_server',
            use: 'in',
            min: 0,
            max: '1',
            documentation: 'URL of a FHIR server. This parameter is required if a test_instance parameter is not provided.',
            type: 'uri'
          },
          {
            name: 'module',
            use: 'in',
            min: 0,
            max: '1',
            documentation: "Available modules: #{available_modules.inspect[1..-2]}. "\
                            'This parameter is required if a test_instance parameter is not provided.',
            type: 'string'
          },
          {
            name: 'client_id',
            use: 'in',
            min: 0,
            max: '1',
            type: 'id'
          },
          {
            name: 'client_secret',
            use: 'in',
            min: 0,
            max: '1',
            type: 'string'
          },
          {
            name: 'client_endpoint_key',
            use: 'in',
            min: 0,
            max: '1',
            documentation: "If none is provided, the default is 'static'.",
            type: 'string'
          }
        ]
      )
    end

    def structure_definition_test_instance
      FHIR::StructureDefinition.new(
        id: 'structure_definition_test_instance',
        url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_test_instance',
        name: 'test_instance',
        title: 'Structure Definition Test Instance',
        status: 'active',
        description: 'Identifier of the testing_instance associated with the TestReport. '\
                      'This identifies the FHIR server and other information that the TestReport represents.',
        kind: 'primitive-type',
        abstract: false,
        context: {
          type: 'element',
          expression: 'TestReport'
        },
        type: 'Extension',
        baseDefinition: 'http://hl7.org/fhir/StructureDefinition/Extension',
        derivation: 'constraint',
        snapshot: {
          element: {
            path: 'TestReport.test_instance',
            min: 1,
            max: '1',
            type: {
              code: 'id'
            }
          }
        }
      )
    end

    def structure_definition_module
      FHIR::StructureDefinition.new(
        id: 'structure_definition_module',
        url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_module',
        name: 'module',
        title: 'Structure Definition Module',
        status: 'active',
        description: "A module defines a related set of TestScripts. The available modules are #{available_modules.inspect[1..-2]}.",
        kind: 'primitive-type',
        abstract: false,
        context: [
          {
            type: 'element',
            expression: 'TestScript'
          },
          {
            type: 'element',
            expression: 'TestReport'
          }
        ],
        type: 'Extension',
        baseDefinition: 'http://hl7.org/fhir/StructureDefinition/Extension',
        derivation: 'constraint',
        snapshot: {
          element: [
            {
              path: 'TestScript.module',
              min: 1,
              max: '*',
              type: {
                code: 'string'
              }
            },
            {
              path: 'TestReport.module',
              min: 1,
              max: '1',
              type: {
                code: 'string'
              }
            }
          ]
        }
      )
    end

    # This complex extension is probably written incorrectly
    def structure_definition_client_state
      FHIR::StructureDefinition.new(
        id: 'structure_definition_client_state',
        url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/structure_definition_client_state',
        name: 'client_state',
        title: 'Structure Definition Client State',
        status: 'active',
        description: 'Defines all of the inputted parameters of the execute operation associated with the state of the test_instance of a TestReport',
        kind: 'complex-type',
        abstract: false,
        context: [
          {
            type: 'element',
            expression: 'TestReport'
          }
        ],
        type: 'Extension',
        baseDefinition: 'http://hl7.org/fhir/StructureDefinition/Extension',
        derivation: 'constraint',
        snapshot: {
          element: [
            {
              path: 'Extension.extension',
              slicing: {
                discrinimator: {
                  type: 'value',
                  path: 'url'
                },
                ordered: true,
                rules: 'closed'
              }
            },
            {
              path: 'Extension.extension.extension',
              min: 0,
              max: '0'
            },
            {
              path: 'Extension.extension',
              sliceName: 'fhir_server',
              short: 'URL of the FHIR server tested',
              min: 1,
              max: '1',
              type: {
                code: 'url'
              }
            },
            {
              path: 'Extension.extension',
              sliceName: 'client_id',
              short: 'Client ID for the fhir_server',
              min: 0,
              max: '1',
              type: {
                code: 'id'
              }
            },
            {
              path: 'Extension.extension',
              sliceName: 'client_secret',
              short: 'Client secret of the client id',
              min: 0,
              max: '1',
              type: {
                code: 'string'
              }
            }
          ]
        }
      )
    end

    def search_parameter_id
      FHIR::SearchParameter.new(
        id: 'search_parameter_id',
        url: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_id',
        name: '_id',
        status: 'active',
        description: 'ID of a resource',
        code: '_id',
        base: [
          'TestScript',
          'TestReport'
        ],
        type: 'string'
      )
    end

    def search_parameter_module
      FHIR::SearchParameter.new(
        id: 'search_parameter_module',
        url: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_module',
        name: 'module',
        status: 'active',
        description: 'module of a TestScript resource (an extension)',
        code: 'module',
        base: ['TestScript'],
        type: 'string'
      )
    end

    def search_parameter_test_instance
      FHIR::SearchParameter.new(
        id: 'search_parameter_test_instance',
        url: 'https://inferno.healthit.gov/inferno/fhir/SearchParameter/search_parameter_test_instance',
        name: 'test_instance',
        status: 'active',
        description: 'test_instance of a TestScript resource (an extension)',
        code: 'test_instance',
        base: ['TestReport'],
        type: 'string'
      )
    end

    def sequence_to_testscript(sequence)
      testscript = FHIR::TestScript.new(
        id: sequence.sequence_name,
        url: "https://inferno.healthit.gov/inferno/fhir/TestScript/#{sequence.sequence_name}",
        name: sequence.title,
        status: 'active',
        description: sequence.description,
        purpose: sequence.details
      )
      module_names = find_modules(sequence)
      module_names&.each_with_index do |mod, index|
        module_extension = FHIR::Extension.new(
          url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/struture_definition_module',
          valueString: mod
        )
        testscript.extension[index] = module_extension
      end
      testscript
    end

    def resource_to_entry(resource)
      entry = FHIR::Bundle::Entry.new(
        search: {
          mode: 'match'
        }
      )
      entry.resource = resource
      entry
    end

    def entries_to_bundle(bundle_id, entries)
      testscript_bundle = FHIR::Bundle.new(
        id: bundle_id,
        type: 'collection',
        total: entries.length
      )
      testscript_bundle.entry = entries
      testscript_bundle
    end

    def not_found_operation_outcome(resource, search_param_type, search_param)
      FHIR::OperationOutcome.new(
        id: 'warning',
        issue: {
          severity: 'warning',
          code: 'not-found',
          details: {
            text: "There is no matching #{resource} for #{search_param_type} #{search_param}"
          }
        }
      )
    end

    def not_found_bundle(operation_outcome)
      bundle = FHIR::Bundle.new(
        id: 'bundle-search-warning',
        type: 'searchset',
        total: 0,
        entry: [
          {
            search: {
              mode: 'outcome'
            }
          }
        ]
      )
      bundle.entry[0].resource = operation_outcome
      bundle
    end

    def results_to_testreport(sequence, results, instance_result)
      testreport = FHIR::TestReport.new(
        id: results.id,
        extension: [
          {
            url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/struture_definition_test_instance',
            valueId: results.testing_instance_id
          },
          {
            url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/struture_definition_module',
            valueString: results.testing_instance.selected_module
          }
        ],
        name: sequence.title + ' Results',
        status: 'completed',
        testScript: {
          reference: "https://inferno.healthit.gov/inferno/fhir/TestScript/#{sequence.sequence_name}"
        },
        result: results.result,
        score: results.required_total.zero? ? 0 : (results.required_passed.to_f / results.required_total) * 100,
        tester: 'Inferno',
        setup: {
          action: [
            operation: {
              result: instance_result,
              message: instance_result_message(instance_result)
            }
          ]
        }
      )
      tests = []
      individual_results = results.test_results
      individual_results.each { |result| tests << result_to_test(result) }
      testreport.test = tests

      testreport.extension[testreport.extension.length] = client_state_extension(results.testing_instance)

      testreport
    end

    def client_state_extension(instance)
      FHIR::Extension.new(
        url: 'https://inferno.healthit.gov/inferno/fhir/StructureDefinition/struture_definition_client_state',
        extension: [
          {
            url: 'fhir_server',
            valueUri: instance.url
          },
          {
            url: 'client_id',
            valueId: instance.client_id
          },
          {
            url: 'client_secret',
            valueString: instance.client_secret
          }
        ]
      )
    end

    def instance_result_message(instance_result)
      if instance_result == 'pass'
        'A new test instance was created to run the TestScript.'
      elsif instance_result == 'skip'
        'An existing test instance was used to run the TestScript given the test_instance as a parameter.'
      end
    end

    def result_to_test(result)
      FHIR::TestReport::Test.new(
        name: result.test_id + ': ' + result.name,
        description: result.description,
        action: [
          operation: {
            result: result.result,
            message: result.message
          }
        ]
      )
    end
  end
end
