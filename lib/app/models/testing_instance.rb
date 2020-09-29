# frozen_string_literal: true

require_relative 'server_capabilities'
require_relative '../utils/result_statuses'
require_relative 'sequence_requirement'

module Inferno
  class TestingInstance < ApplicationRecord
    attribute :id, :string, default: -> { Inferno::SecureRandomBase62.generate(64) }
    attribute :client_name, :string, default: 'Inferno'
    attribute :client_endpoint_key, :string, default: -> { Inferno::SecureRandomBase62.generate(32) }
    attribute :created_at, :datetime, default: -> { DateTime.now }
    attribute :must_support_confirmed, :string, default: ''
    attribute :client_id, :string
    attribute :resource_id, :string
    attribute :group_id, :string
    attribute :bulk_client_id, :string
    attribute :onc_sl_client_id, :string

    has_many :sequence_results
    has_many :resource_references
    has_many :sequence_requirements
    has_one :server_capabilities

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
      sequence_results.find_by(result: 'wait')
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
        .where(resource_type: 'Patient')
        .order(created_at: :asc)
        .first
        &.resource_id
    end

    def patient_id=(patient_id)
      return if patient_id.to_s == self.patient_id.to_s

      resource_references.destroy_all

      unless patient_ids.nil?
        self.patient_ids = patient_ids.split(',').append(patient_id).uniq.join(',')
      end

      ResourceReference.create!(
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
        .where(resource_type: type, resource_id: id, testing_instance_id: self.id)
        .delete_all

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

    def get_sequence_requirement(requirement)
      return unless requirement&.dig(:name)

      attributes = { testing_instance: self,
                     label: requirement[:name],
                     value: '' }
        .merge(requirement)

      Inferno::SequenceRequirement
        .find_or_create_by(name: requirement[:name], testing_instance: self) do |requirement_instance|
          requirement_instance.assign_attributes(attributes)
          requirement_instance.save!
        end
    end

    def add_sequence_requirements(requirements)
      return unless requirements.present?

      requirements.each do |requirement, req_desciption|
        get_sequence_requirement(name: requirement.to_s, label: req_desciption[:label], description: req_desciption[:description])
      end
    end

    def get_requirement_value(requirement_name)
      get_sequence_requirement(name: requirement_name.to_s, testing_instance: self).value
    end

    def set_requirement_value(requirement_name, value)
      get_sequence_requirement(name: requirement_name.to_s, testing_instance: self).update!(value: value)
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
