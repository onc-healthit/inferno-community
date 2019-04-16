require 'dm-core'
require 'dm-migrations'

module Inferno
  module Models
    class TestingInstance
      include DataMapper::Resource
      property :id, String, key: true, default: proc { Inferno::SecureRandomBase62.generate(64) }
      property :url, String
      property :name, String
      property :confidential_client, Boolean
      property :client_id, String
      property :client_secret, String
      property :base_url, String

      property :client_name, String, default: 'Inferno'
      property :scopes, String
      property :launch_type, String
      property :state, String
      property :selected_module, String

      property :oauth_authorize_endpoint, String
      property :oauth_token_endpoint, String
      property :oauth_register_endpoint, String

      property :client_endpoint_key, String, default: proc { Inferno::SecureRandomBase62.generate(32) }

      property :token, String
      property :id_token, String
      property :refresh_token, String
      property :created_at, DateTime, default: proc { DateTime.now }

      property :standalone_launch_script, String
      property :ehr_launch_script, String
      property :manual_registration_script, String

      property :initiate_login_uri, String
      property :redirect_uris, String

      property :dynamic_registration_token, String

      has n, :sequence_results
      has n, :supported_resources, order: [:index.asc]
      has n, :resource_references

      def latest_results
        self.sequence_results.reduce({}) do |hash, result|
          if hash[result.name].nil? || hash[result.name].created_at < result.created_at
            hash[result.name] = result
          end
          hash
        end
      end

      def latest_results_by_case
        self.sequence_results.reduce({}) do |hash, result|
          if hash[result.test_case_id].nil? || hash[result.test_case_id].created_at < result.created_at
            hash[result.test_case_id] = result
          end
          hash
        end
      end

      def group_results(test_set_id)
        return_data = []
        results = latest_results_by_case

        self.module.test_sets[test_set_id.to_sym].groups.each do |group|
          pass_count = 0
          failure_count = 0;
          total_count = 0;
          result_details = group.test_cases.reduce(cancel: 0, pass: 0, skip: 0, fail: 0, error: 0, total: 0) do |hash, val|
            
            if results.has_key?(val.id)
              hash[results[val.id].result.to_sym] = 0 if !hash.has_key?(results[val.id].result.to_sym)
              hash[results[val.id].result.to_sym] += 1
              hash[:total] += 1
            end

            hash
          end


          result = :pass
          result = :skip if result_details[:skip] > 0
          result = :fail if result_details[:fail] > 0
          result = :fail if result_details[:cancel] > 0
          result = :error if result_details[:error] > 0
          result = :not_run if result_details[:total] == 0

          return_data << { group: group, result_details: result_details, result: result, missing_variables: group.lock_variables.select{|var| self.send(var.to_sym).nil?} }

          return_data
        end
        
        return_data
      end

      def waiting_on_sequence
        self.sequence_results.first(result: 'wait')
      end

      def final_result

        required_sequences = Inferno::Sequence::SequenceBase.subclasses.reject(&:optional?)

        all_passed = required_sequences.all? do |sequence|
          self.latest_results[sequence.name].try(:result) == 'pass'
        end

        if all_passed
          return 'pass'
        else
          return 'fail'
        end

      end

      def module
        Inferno::Module.get(self.selected_module)
      end
    end
  end
end
