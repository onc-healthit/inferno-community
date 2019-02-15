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

      def fhir_version
        self.module.fhir_version
      end

      def module
        Inferno::Module.get(self.selected_module)
      end

      def patient_id
        self.resource_references.select{|ref| ref.resource_type == 'Patient'}.first.try(:resource_id)
      end

      def patient_id= patient_id
        return if patient_id.to_s == self.patient_id.to_s

        existing_patients = self.resource_references.select{|ref| ref.resource_type == 'Patient'}
        # Use destroy directly (instead of on each, so we don't have to reload)
        self.resource_references.destroy
        self.save!

        self.resource_references << ResourceReference.new({
                                                              resource_type: 'Patient',
                                                              resource_id: patient_id
                                                          })

      end

      def save_supported_resources(conformance)

        resources = ['Patient',
                     'AllergyIntolerance',
                     'CarePlan',
                     'Condition',
                     'Device',
                     'DiagnosticReport',
                     'DocumentReference',
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

        supported_resources = conformance.rest.first.resource.select{ |r| resources.include? r.type}.reduce({}){|a,k| a[k.type] = k; a}

        self.supported_resources.each(&:destroy)
        self.save!

        resources.each_with_index do |resource_name, index|

          resource = supported_resources[resource_name]

          read_supported = resource && resource.interaction && resource.interaction.any?{|i| i.code == 'read'}

          self.supported_resources << SupportedResource.create({
                                                                   resource_type: resource_name,
                                                                   index: index,
                                                                   testing_instance_id: self.id,
                                                                   supported: !resource.nil?,
                                                                   read_supported: read_supported,
                                                                   vread_supported: resource && resource.interaction && resource.interaction.any?{|i| i.code == 'vread'},
                                                                   search_supported: resource && resource.interaction && resource.interaction.any?{|i| i.code == 'search-type'},
                                                                   history_supported: resource && resource.interaction && resource.interaction.any?{|i| i.code == 'history-instance'}
                                                               })
        end

        self.save!

      end

      def conformance_supported?(resource, methods = [])

        resource_support = self.supported_resources.find {|r| r.resource_type == resource.to_s}
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
        self.resource_references.each do |ref|
          if (ref.resource_type == resource_type) && (ref.resource_id == resource_id)
            ref.destroy
          end
        end
        self.resource_references << ResourceReference.new({resource_type: resource_type,
                                                          resource_id: resource_id})
        self.save!
        # Ensure the instance resource references are accurate
        self.reload
      end
    end
  end
end
