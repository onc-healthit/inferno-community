# frozen_string_literal: true

require 'dm-core'
require 'dm-migrations'
require_relative '../utils/result_statuses'

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

      property :conformance_checked, Boolean
      property :oauth_authorize_endpoint, String
      property :oauth_token_endpoint, String
      property :oauth_register_endpoint, String
      property :fhir_format, String

      property :dynamically_registered, Boolean
      property :client_endpoint_key, String, default: proc { Inferno::SecureRandomBase62.generate(32) }

      property :token, String
      property :token_retrieved_at, DateTime
      property :id_token, String
      property :refresh_token, String
      property :created_at, DateTime, default: proc { DateTime.now }

      property :oauth_introspection_endpoint, String
      property :resource_id, String
      property :resource_secret, String
      property :introspect_token, String
      property :introspect_refresh_token, String

      property :standalone_launch_script, String
      property :ehr_launch_script, String
      property :manual_registration_script, String

      property :initiate_login_uri, String
      property :redirect_uris, String

      property :dynamic_registration_token, String

      property :must_support_confirmed, String, default: ''

      has n, :sequence_results
      has n, :supported_resources, order: [:index.asc]
      has n, :resource_references

      def latest_results
        sequence_results.each_with_object({}) do |result, hash|
          hash[result.name] = result if hash[result.name].nil? || hash[result.name].created_at < result.created_at
        end
      end

      def latest_results_by_case
        sequence_results.each_with_object({}) do |result, hash|
          if hash[result.test_case_id].nil? || hash[result.test_case_id].created_at < result.created_at
            hash[result.test_case_id] = result
          end
        end
      end

      def group_results(test_set_id)
        return_data = []
        results = latest_results_by_case

        self.module.test_sets[test_set_id.to_sym].groups.each do |group|
          result_details = group.test_cases.each_with_object(Hash.new(0)) do |test_case, hash|
            id = test_case.id
            next unless results.key?(id)

            hash[results[id].result.to_sym] += 1
            hash[:total] += 1
          end

          return_data << {
            group: group,
            result_details: result_details,
            result: group_result(result_details),
            missing_variables: group.lock_variables.select { |var| send(var.to_sym).nil? }
          }
        end

        return_data
      end

      def waiting_on_sequence
        sequence_results.first(result: 'wait')
      end

      def all_test_cases(test_set_id)
        self.module.test_sets[test_set_id.to_sym].groups.flat_map(&:test_cases)
      end

      def all_passed?(test_set_id)
        latest_results = latest_results_by_case

        all_test_cases(test_set_id).all? do |test_case|
          latest_results[test_case.id]&.pass?
        end
      end

      def any_failed?(test_set_id)
        latest_results = latest_results_by_case

        all_test_cases(test_set_id).any? do |test_case|
          latest_results[test_case.id]&.fail?
        end
      end

      def final_result(test_set_id)
        if all_passed?(test_set_id)
          Inferno::ResultStatuses::PASS
        else
          any_failed?(test_set_id) ? Inferno::ResultStatuses::FAIL : Inferno::ResultStatuses::PENDING
        end
      end

      def fhir_version
        self.module.fhir_version
      end

      def module
        @module ||= Inferno::Module.get(selected_module)
      end

      def patient_id
        resource_references
          .select { |ref| ref.resource_type == 'Patient' }
          .first&.resource_id
      end

      def patient_id=(patient_id)
        return if patient_id.to_s == self.patient_id.to_s

        resource_references.destroy

        save!

        resource_references << ResourceReference.new(
          resource_type: 'Patient',
          resource_id: patient_id
        )

        save!

        reload
      end

      def save_supported_resources(conformance)
        resources = ['Patient',
                     'AllergyIntolerance',
                     'CarePlan',
                     'Condition',
                     'Device',
                     'DiagnosticReport',
                     'DocumentReference',
                     'Encounter',
                     'ExplanationOfBenefit',
                     'Goal',
                     'Immunization',
                     'Medication',
                     'MedicationDispense',
                     'MedicationStatement',
                     'MedicationOrder',
                     'Observation',
                     'Procedure',
                     'DocumentReference',
                     'Provenance']

        supported_resource_capabilities =
          conformance
            .rest.first.resource
            .select { |resource| resources.include? resource.type }
            .each_with_object({}) { |resource, hash| hash[resource.type] = resource }

        supported_resources.each(&:destroy)
        save!

        resources.each_with_index do |resource_name, index|
          capabilities = supported_resource_capabilities[resource_name]

          supported_resources << SupportedResource.create(
            resource_type: resource_name,
            index: index,
            testing_instance_id: id,
            supported: !capabilities.nil?,
            read_supported: interaction_supported?(capabilities, 'read'),
            vread_supported: interaction_supported?(capabilities, 'vread'),
            search_supported: interaction_supported?(capabilities, 'search-type'),
            history_supported: interaction_supported?(capabilities, 'history-instance')
          )
        end

        save!
      end

      def conformance_supported?(resource, methods = [])
        resource_support = supported_resources.find { |r| r.resource_type == resource.to_s }
        return false if resource_support.nil? || !resource_support.supported

        methods.all? do |method|
          case method
          when :read
            resource_support.read_supported
          when :search
            resource_support.search_supported
          when :history
            resource_support.history_supported
          when :vread
            resource_support.vread_supported
          else
            false
          end
        end
      end

      def post_resource_references(resource_type: nil, resource_id: nil)
        resource_references.each do |ref|
          ref.destroy if (ref.resource_type == resource_type) && (ref.resource_id == resource_id)
        end
        resource_references << ResourceReference.new(resource_type: resource_type,
                                                     resource_id: resource_id)
        save!
        # Ensure the instance resource references are accurate
        reload
      end

      private

      def interaction_supported?(capabilities, interaction_code)
        capabilities&.interaction&.any? { |i| i.code == interaction_code }
      end

      def group_result(results)
        return :skip if results[:skip].positive?
        return :fail if results[:fail].positive?
        return :fail if results[:cancel].positive?
        return :error if results[:error].positive?
        return :not_run if results[:total].zero?

        :pass
      end
    end
  end
end
