# frozen_string_literal: true

require 'sinatra/json'
require 'sinatra/base'
require_relative 'api_json'
require_relative 'api_helper'

module Inferno
  class App
    class Endpoint
      class Api < Endpoint
        include Inferno::ApiJsonDefinitions
        include Inferno::ApiHelper

        set :prefix, '/api/v1'

        before do
          headers 'Content-Type' => 'application/json+ndjson'
        end

        # Get all test_sets
        get '/test_set' do
          available_test_sets.to_json
        end

        # Get test_set by id
        get '/test_set/:test_set_id' do
          test_set_by_id(params[:test_set_id]).to_json
        end

        # Get all presets
        get '/preset' do
          presets = filter_presets
          presets&.map { |preset| preset_to_hash(preset[0], preset[1]) }.to_json
        end

        # Get preset by id
        get '/preset/:preset_id' do
          preset = find_preset(params[:preset_id])
          preset_to_hash(params[:preset_id], preset).to_json
        end

        # Create instance
        post '/instance' do
          instance = new_instance(verify_parameters_body)
          instance_to_hash(instance).to_json
        end

        # Get instance by id
        get '/instance/:instance_id' do
          instance = find_instance(params[:instance_id])
          instance_to_hash(instance).to_json
        end

        # Get module
        get '/instance/:instance_id/module' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          module_to_hash(mod, instance.id).to_json
        end

        # Get all groups
        get '/instance/:instance_id/module/group' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          groups_to_hash(mod, instance.id).to_json
        end

        # Get group by id
        get '/instance/:instance_id/module/group/:group_id' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          group_to_hash(group, instance.id, find_view(mod)).to_json
        end

        # Get all sequences
        get '/instance/:instance_id/module/group/:group_id/sequence' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          sequences_to_hash(group, instance.id, find_view(mod)).to_json
        end

        # Get sequence by id
        get '/instance/:instance_id/module/group/:group_id/sequence/:sequence_id' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          sequence = find_sequence(params[:sequence_id], group)
          sequence_to_hash(sequence, instance.id, group.id, find_view(mod)).to_json
        end

        # Get all results
        get '/instance/:instance_id/result' do
          instance = find_instance(params[:instance_id])
          results = instance.latest_results
          results.map { |result| result_to_hash(result[1]) }.to_json
        end

        # Get result by id
        get '/instance/:instance_id/result/:result_id' do
          instance = find_instance(params[:instance_id])
          result = find_result(params[:result_id])
          verify_result_to_instance(result, instance)
          result_to_hash(result).to_json
        end

        # Get results by group
        get '/instance/:instance_id/result/group/:group_id' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          find_group(params[:group_id], mod) # Check for valid group
          results_in_group = results_by_group(params[:group_id], instance)
          results_in_group.map { |result| result_to_hash(result[1]) }.to_json
        end

        # Get results by sequence
        get '/instance/:instance_id/result/group/:group_id/sequence/:sequence_id' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          find_sequence(params[:sequence_id], group) # Check for valid sequence

          result = results_by_sequence(params[:sequence_id], params[:group_id], instance)
          result.nil? ? {}.to_json : result_to_hash(result[1]).to_json
        end

        # Get all requests
        get '/instance/:instance_id/result/:result_id/request' do
          instance = find_instance(params[:instance_id])
          result = find_result(params[:result_id])
          verify_result_to_instance(result, instance)
          requests = http_requests(result)
          requests.each_with_index.map { |request, index| request_to_hash(request, index, result) }.to_json
        end

        # Get request by id
        get '/instance/:instance_id/result/:result_id/request/:response_id' do
          instance = find_instance(params[:instance_id])
          result = find_result(params[:result_id])
          verify_result_to_instance(result, instance)
          request = find_request(params[:response_id], result)
          request_to_hash(request, params[:response_id], result).to_json
        end

        # Get report
        get '/instance/:instance_id/report' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)

          request_response_count = Inferno::Models::RequestResponse.all(instance_id: instance.id).count
          latest_sequence_time =
            if instance.sequence_results.count.positive?
              Inferno::Models::SequenceResult.first(testing_instance: instance).created_at.strftime('%m/%d/%Y %H:%M')
            else
              'No tests ran'
            end

          report_to_hash(instance, mod, request_response_count, latest_sequence_time).to_json
        end

        # Execute group
        post '/instance/:instance_id/module/group/:group_id/$execute' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          sequences = group.test_cases.map(&:sequence)

          valid_group_run = mod.test_sets.first[1].view == 'guided' || group.run_all
          error_message = error_to_hash("Group '#{params[:group_id]}' cannot be run automatically. Please run each sequence in this group individually.")
          halt 400, error_message.to_json unless valid_group_run

          execute_tests(sequences, instance, mod.default_test_set, group.id).to_json
        end

        # Execute sequence
        post '/instance/:instance_id/module/group/:group_id/sequence/:sequence_id/$execute' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          sequence = find_sequence(params[:sequence_id], group)

          valid_sequence_run = mod.test_sets.first[1].view == 'default'
          error_message = error_to_hash("Sequence '#{params[:sequence_id]}' cannot be run individually. Please run this sequence as a part of the group '#{params[:group_id]}.'")
          halt 400, error_message.to_json unless valid_sequence_run

          result = execute_tests([sequence], instance, mod.default_test_set, group.id)
          result[0].to_json
        end

        # Execute group with stream
        post '/instance/:instance_id/module/group/:group_id/$execute_stream' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          sequence_classes = group.test_cases.map(&:sequence)
          sequences = sequence_classes.map { |seq_class| sequence_class_to_sequence(seq_class, instance) }

          valid_group_run = mod.test_sets.first[1].view == 'guided' || group.run_all
          error_message = error_to_hash("Group '#{params[:group_id]}' cannot be run automatically. Please run each sequence in this group individually.")
          halt 404, error_message.to_json unless valid_group_run

          run_with_stream(sequences, params[:group_id], mod.default_test_set, true)
        end

        # Execute sequence with stream
        post '/instance/:instance_id/module/group/:group_id/sequence/:sequence_id/$execute_stream' do
          instance = find_instance(params[:instance_id])
          mod = Inferno::Module.get(instance.selected_module)
          group = find_group(params[:group_id], mod)
          sequence_class = find_sequence(params[:sequence_id], group)
          sequence = sequence_class_to_sequence(sequence_class, instance)

          valid_sequence_run = mod.test_sets.first[1].view == 'default'
          error_message = error_to_hash("Sequence '#{params[:sequence_id]}' cannot be run individually. Please run this sequence as a part of the group '#{params[:group_id]}.'")
          halt 404, error_message.to_json unless valid_sequence_run

          run_with_stream([sequence], params[:group_id], mod.default_test_set, false)
        end
      end
    end
  end
end
