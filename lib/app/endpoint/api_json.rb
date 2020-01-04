# frozen_string_literal: true

require 'sinatra/json'

# Creates JSON objects for api.rb
module Inferno
  module ApiJsonDefinitions
    # Update the base url for references based on actual base url
    BASE_URL = 'http://localhost:4567/' # 'https://inferno.healthit.gov/'
    API_VERSION = 'api/v1/'
    PREFIX = "#{BASE_URL}#{API_VERSION}"

    def test_set_to_hash(test_set)
      {
        type: 'test_set',
        id: test_set.name,
        name: test_set.title,
        url: "#{PREFIX}test_set/#{test_set.name}",
        description: test_set.description,
        fhir_version: test_set.fhir_version
      }.compact
    end

    def preset_to_hash(id, preset)
      {
        type: 'preset',
        id: id,
        name: preset[:name],
        url: "#{PREFIX}preset/#{id}",
        fhir_server: preset[:uri],
        test_set: preset[:module],
        client_id: preset[:client_id],
        client_secret: preset[:client_secret],
        instructions: preset[:instructions]
      }.compact
    end

    def instance_to_hash(instance)
      instance_hash = {
        type: 'instance',
        id: instance.id,
        url: "#{PREFIX}instance/#{instance.id}",
        reference: {
          module_url: "#{PREFIX}instance/#{instance.id}/module",
          results_url: "#{PREFIX}instance/#{instance.id}/result"
        },
        fhir_uri: instance.url,
        fhir_version: instance.fhir_version,
        created_at: instance.created_at,
        oauth_server_endpoints: {
          oauth_auth: instance.oauth_authorize_endpoint,
          oauth_token: instance.oauth_token_endpoint,
          oauth_reg: instance.oauth_register_endpoint
        },
        client_oauth_endpoints: {
          launch_uri: instance.initiate_login_uri,
          redirect_uri: instance.redirect_uris
        },
        oauth_client_data: {
          scopes: instance.scopes,
          client_id: instance.client_id,
          client_secret: instance.client_secret,
          client_state: instance.state,
          bearer_token: instance.token,
          refresh_token: instance.refresh_token
        }
      }
      instance_hash[:oauth_server_endpoints].compact!
      instance_hash.delete(:oauth_server_endpoints) if instance_hash[:oauth_server_endpoints].blank?
      instance_hash[:oauth_client_data].compact!

      instance_hash
    end

    def module_to_hash(mod, instance_id)
      {
        type: 'module',
        id: mod.name,
        name: mod.title,
        url: "#{PREFIX}instance/#{instance_id}/module",
        reference: {
          instance_url: "#{PREFIX}instance/#{instance_id}"
        },
        description: mod.description,
        fhir_version: mod.fhir_version,
        groups: groups_to_hash(mod, instance_id)
      }.compact
    end

    def groups_to_hash(mod, instance_id)
      mod.test_sets.first[1].groups.map { |group| group_to_hash(group, instance_id, find_view(mod)) }
    end

    def group_to_hash(group, instance_id, view)
      group_hash = {
        type: 'group',
        id: group.id,
        name: group.name,
        url: "#{PREFIX}instance/#{instance_id}/module/group/#{group.id}",
        reference: {
          instance_url: "#{PREFIX}instance/#{instance_id}",
          group_results_url: "#{PREFIX}instance/#{instance_id}/result/group/#{group.id}"
        },
        description: group.overview,
        instructions: group.input_instructions,
        run: view == 'guided' || group.run_all
      }.compact

      group_hash[:reference][:group_execute_url] = "#{PREFIX}instance/#{instance_id}/module/group/#{group.id}/$execute" if group_hash[:run]
      group_hash[:sequences] = sequences_to_hash(group, instance_id, view)
      group_hash
    end

    def sequences_to_hash(group, instance_id, view)
      group.test_cases.map { |test_case| sequence_to_hash(test_case.sequence, instance_id, group.id, view) }
    end

    def sequence_to_hash(sequence, instance_id, group_id, view)
      sequence_hash = {
        type: 'sequence',
        id: sequence.sequence_name,
        name: sequence.title,
        url: "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence/#{sequence.sequence_name}",
        reference: {
          instance_url: "#{PREFIX}instance/#{instance_id}",
          group_url: "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}",
          sequence_results_url: "#{PREFIX}instance/#{instance_id}/result/group/#{group_id}/sequence/#{sequence.sequence_name}"
        },
        description: sequence.description,
        about: sequence.details,
        run: view == 'default'
      }.compact
      execute_url = "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence/#{sequence.sequence_name}/$execute"
      sequence_hash[:reference][:sequence_execute_url] = execute_url if sequence_hash[:run]
      sequence_hash[:tests] = sequence.tests.map { |test| test_to_hash(test) }

      sequence_hash
    end

    def test_to_hash(test)
      {
        name: test[:test_id],
        description: test[:name],
        details: test[:description],
        required: test[:required],
        url: test[:url]
      }.compact
    end

    def result_to_hash(result)
      group_id = find_group_by_result(result.test_case_id)

      result_hash = {
        type: 'result',
        id: result.id,
        name: result.name,
        url: "#{PREFIX}instance/#{result.testing_instance_id}/result/#{result.id}",
        references: {
          instance_url: "#{PREFIX}instance/#{result.testing_instance_id}",
          group_url: "#{PREFIX}instance/#{result.testing_instance_id}/module/group/#{group_id}",
          sequence_url: "#{PREFIX}instance/#{result.testing_instance_id}/module/group/#{group_id}/sequence/#{result.name}"
        },
        status: result.result,
        created_at: result.created_at,
        counts: {
          required_passed: result.required_passed,
          required_total: result.required_total,
          optional_passed: result.optional_passed,
          optional_total: result.optional_total
        },
        inputs: JSON.parse(result.input_params)
      }

      test_list = result.test_results.map { |res| test_result_to_hash(res) }

      outputs = output_results(result.output_results)
      result_hash[:outputs] = outputs unless outputs.blank?

      http = http_requests_hash(http_requests(result), result)
      result_hash[:http_requests] = http unless http.blank?

      result_hash[:test_list] = test_list

      result_hash
    end

    def http_requests(result)
      result.test_results.map { |res| res.request_responses.find_all(&:present?) }.flatten
    end

    def http_requests_hash(http_requests, result)
      http_requests.each_with_index.map do |request, index|
        {
          request: "#{request.request_method.upcase} #{'INBOUND' if request.direction == 'inbound'} #{request.response_code} #{request.request_url}",
          details: "#{PREFIX}instance/#{result.testing_instance_id}/result/#{result.id}/request/#{index}"
        }
      end
    end

    def test_result_to_hash(result)
      {
        name: result.test_id,
        description: result.name,
        status: result.result,
        message: result.message,
        details: result.details
      }.select { |_, value| value.present? }
    end

    def output_results(outputs)
      new_outputs = {}
      outputs = JSON.parse(outputs) unless outputs.nil?
      outputs&.each { |key, val| new_outputs[key] = val['updated'] }
      new_outputs
    end

    def request_to_hash(request, request_id, result)
      request_hash = {
        type: 'request',
        id: request_id,
        name: "#{request.request_method.upcase} #{'INBOUND' if request.direction == 'inbound'} #{request.response_code} #{request.request_url}",
        url: "#{PREFIX}instance/#{result.testing_instance_id}/result/#{result.id}/request/#{request_id}",
        references: {
          instance_url: "#{PREFIX}instance/#{result.testing_instance_id}",
          result_url: "#{PREFIX}instance/#{result.testing_instance_id}/result/#{result.id}"
        },
        request: {},
        response: {
          headers: request.response_headers
        }
      }

      request_hash[:request][:headers] = request.request_headers unless request.request_headers == '{}'
      request_hash[:request][:payload] = request.request_payload unless request.request_payload.blank?
      request_hash.delete(:request) if request_hash[:request].blank?

      request_hash[:response][:body] = request.response_body.nil? ? nil : Base64.strict_encode64(request.response_body)
      request_hash.delete(:response) if request_hash[:response].compact.blank?

      request_hash
    end

    def report_to_hash(instance, mod, request_response_count, latest_sequence_time)
      report_hash = {
        type: 'report',
        id: 'report',
        name: "#{instance.module.title} Test Report",
        url: "#{PREFIX}instance/#{instance.id}/report",
        references: {
          instance_url: "#{PREFIX}instance/#{instance.id}",
          module_url: "#{PREFIX}instance/#{instance.id}/module",
          results_url: "#{PREFIX}instance/#{instance.id}/results"
        },
        last_updated: latest_sequence_time,
        report_url: "#{request.base_url}#{base_path}/#{instance.id}/#{mod.default_test_set}/",
        final_result: instance.final_result(mod.default_test_set),
        request_response: request_response_count,
        resource_references: instance.resource_references.count,
        supported_resources: instance.supported_resources.count,
        fhir_version: instance.fhir_version&.upcase,
        inferno_version: VERSION
      }

      test_set = instance.module.test_sets[mod.default_test_set.to_sym]
      sequence_results = instance.latest_results_by_case
      report_hash[:results_summary] = report_summary(test_set, sequence_results)

      report_hash
    end

    def report_summary(test_set, sequence_results)
      report_summary = []

      test_set.groups.each do |group|
        report_summary << {
          group_name: group.name,
          sequences: report_summary_groups(group, sequence_results)
        }
      end
      report_summary
    end

    # This code is copied/similar to report.erb and test_case.erb
    def report_summary_groups(group, sequence_results)
      test_cases_hash = []
      group.test_cases.each do |test_case|
        test_case_hash = {}
        sequence_result = sequence_results[test_case.id]

        test_case_hash[:sequence_name] = test_case.title
        test_case_hash[:status] = sequence_results[test_case.id].try(:result)
        test_case_hash[:status] = 'Not run' if test_case_hash[:status].nil?
        test_case_hash[:description] = test_case.description

        if sequence_results[test_case.id].nil?
          test_case_hash[:test_count] = test_case.sequence.test_count
        else
          test_case_hash[:required_tests_passed] = "#{sequence_results[test_case.id].required_passed}/#{sequence_results[test_case.id].required_total}"
          if sequence_results[test_case.id].optional_total.positive?
            test_case_hash[:optional_tests_passed] = "#{sequence_results[test_case.id].optional_passed}/#{sequence_results[test_case.id].optional_total}"
          end
        end

        if !sequence_results[test_case.id].nil? && !sequence_results[test_case.id].input_params.nil?
          test_case_hash[:inputs] = {}
          JSON.parse(sequence_result.input_params).each { |type, value| test_case_hash[:inputs][type] = value }
        end

        test_case_hash[:test_list] = test_list_hash(sequence_result, test_case.sequence)
        test_case_hash[:outputs] = output_results(sequence_result.output_results) if !sequence_results[test_case.id].nil? && !sequence_results[test_case.id].output_results.blank?

        test_cases_hash << test_case_hash
      end
      test_cases_hash
    end

    def test_list_hash(sequence_result, sequence_class)
      test_list = []
      test_list = test_list_hash_with_results(test_list, sequence_result)
      test_list = test_list_hash_no_results(test_list, sequence_result, sequence_class)
      test_list
    end

    # Test List for tests that have been run
    def test_list_hash_with_results(test_list, sequence_result)
      sequence_result&.test_results&.each do |result, _index|
        test = {}
        optional = result.required ? '' : 'OPTIONAL | '
        test[:name] = "#{result.test_id}: #{optional}#{result.name}"
        test[:status] = result.result

        if result.request_responses.find { |f| f.direction == 'outbound' }.present?
          test[:http_requests] = 'outbound'
        elsif result.request_responses.find { |f| f.direction == 'inbound' }.present?
          test[:http_requests] = 'inbound'
        end

        unless result.message.nil?
          required = result.required ? '' : 'This optional test is not required for conformance.'
          test[:details] = "#{result.message} #{required}"
        end

        test_list << test
      end
      test_list
    end

    # Test list for tests that have not been run
    def test_list_hash_no_results(test_list, sequence_result, sequence_class)
      start_at = 0
      start_at = [sequence_result.test_results.length, sequence_class.tests.length].min unless sequence_result.nil?
      sequence_class.tests[start_at..-1].each_with_index do |test, _index|
        optional = test[:required] ? '' : 'OPTIONAL | '
        test_list << { name: "#{test[:test_id]}: #{optional}#{test[:name]}" }
      end
      test_list
    end

    def error_to_hash(message)
      {
        type: 'error',
        description: message
      }
    end

    def unknown_id_message(type, id)
      "Unknown #{type} id '#{id}'"
    end

    def stream_to_hash(sequence, count, total_count, total_tests)
      {
        type: 'update',
        sequence: {
          sequence_name: sequence.class.title,
          sequence_count: count,
          sequence_total: sequence.test_count
        },
        group: {
          group_count: total_count,
          group_total: total_tests
        }
      }
    end
  end
end
