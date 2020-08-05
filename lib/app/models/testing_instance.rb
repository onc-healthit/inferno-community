# frozen_string_literal: true

require 'dm-core'
require 'dm-migrations'
require_relative 'server_capabilities'
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
      property :received_scopes, String
      property :encounter_id, String
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
      property :token_expires_in, Integer
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

      property :group_id, String

      property :data_absent_code_found, Boolean
      property :data_absent_extension_found, Boolean

      # Bulk Data Parameters
      property :bulk_url, String
      property :bulk_token_endpoint, String
      property :bulk_client_id, String
      property :bulk_system_export_endpoint, String
      property :bulk_patient_export_endpoint, String
      property :bulk_group_export_endpoint, String
      property :bulk_fastest_resource, String
      property :bulk_requires_auth, String
      property :bulk_since_param, String
      property :bulk_jwks_url_auth, String
      property :bulk_jwks_auth, String
      property :bulk_public_key, String
      property :bulk_private_key, String
      property :bulk_access_token, String
      property :bulk_lines_to_validate, String
      property :bulk_status_output, String

      has n, :sequence_results
      has n, :resource_references
      has n, :sequence_requirements
      has 1, :server_capabilities

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

      def fhir_version_match?(versions)
        return true if fhir_version.blank?

        versions.include? fhir_version.to_sym
      end

      def module
        @module ||= Inferno::Module.get(selected_module)
      end

      def patient_id
        resource_references
          .first(resource_type: 'Patient', order: [:created_at.asc])
          &.resource_id
      end

      def patient_id=(patient_id)
        return if patient_id.to_s == self.patient_id.to_s

        resource_references.destroy

        unless patient_ids.nil?
          self.patient_ids = patient_ids.split(',').append(patient_id).uniq.join(',')
        end

        ResourceReference.create(
          resource_type: 'Patient',
          resource_id: patient_id,
          testing_instance: self
        )

        save!

        reload
      end

      def testable_resources
        self.module.resources_to_test & (server_capabilities&.supported_resources || Set.new)
      end

      def supported_resource_interactions
        return [] if server_capabilities.blank?

        resources = testable_resources
        server_capabilities.supported_interactions.select do |interactions|
          resources.include? interactions[:resource_type]
        end
      end

      def conformance_supported?(resource, methods = [], operations = [])
        resource_support = supported_resource_interactions.find do |interactions|
          interactions[:resource_type] == resource.to_s
        end

        return false if resource_support.blank?

        methods_supported = methods.all? do |method|
          method = method == :history ? 'history-instance' : method.to_s

          resource_support[:interactions].include? method
        end

        operations_supported = operations.all? do |operation|
          resource_support[:operations].include? operation.to_s
        end

        methods_supported && operations_supported
      end

      def save_resource_reference_without_reloading(type, id, profile = nil)
        ResourceReference
          .all(resource_type: type, resource_id: id, testing_instance_id: self.id)
          .destroy

        ResourceReference.create!(
          resource_type: type,
          resource_id: id,
          profile: profile,
          testing_instance: self
        )
      end

      def save_resource_references(klass, resources, profile = nil)
        resources
          .select { |resource| resource.is_a? klass }
          .each do |resource|
            save_resource_reference_without_reloading(klass.name.demodulize, resource.id, profile)
          end

        # Ensure the instance resource references are accurate
        reload
      end

      def save_resource_ids_in_bundle(klass, reply, profile = nil)
        return if reply&.resource&.entry&.blank?

        resources = reply.resource.entry.map(&:resource)

        save_resource_references(klass, resources, profile)
      end

      def versioned_conformance_class
        if fhir_version == 'dstu2'
          FHIR::DSTU2::Conformance
        elsif fhir_version == 'stu3'
          FHIR::STU3::CapabilityStatement
        else
          FHIR::CapabilityStatement
        end
      end

      def token_expiration_time
        token_retrieved_at + token_expires_in.seconds
      end

      def add_sequence_requirements(requirements)
        return unless requirements.present?

        requirements.each do |requirement, texts|
          SequenceRequirement.create(
            name: requirement,
            value: '',
            label: texts[:label],
            description: texts[:description],
            testing_instance: self
          )
        end
      end

      def get_requirement_value(requirement_name)
        requirement = sequence_requirements.find { |req| req.name == requirement_name.to_s }
        return requirement.value if requirement.present?

        # add requirement if not included from module file
        new_requirement = SequenceRequirement.new(
          name: requirement_name.to_s,
          value: '',
          label: requirement_name.to_s
        )
        sequence_requirements.push(new_requirement)
        save!
        ''
      end

      def set_requirement_value(requirement_name, value)
        requirement = sequence_requirements.find { |req| req.name == requirement_name.to_s }
        if requirement.present?
          requirement.value = value
        else
          # add requirement if not included from module file
          new_requirement = SequenceRequirement.new(
            name: requirement_name.to_s,
            value: value,
            label: requirement_name.to_s
          )
          sequence_requirements.push(new_requirement)
        end
        save!
      end

      private

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
