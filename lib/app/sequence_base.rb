require_relative 'utils/assertions'
require_relative 'utils/skip_helpers'
require_relative 'ext/fhir_client'
require_relative 'utils/logged_rest_client'
require_relative 'utils/exceptions'
require_relative 'utils/validation'
require_relative 'utils/web_driver'

module Inferno
  module Sequence
    class SequenceBase

      include Assertions
      include SkipHelpers
      include Inferno::WebDriver

      STATUS = {
          pass: 'pass',
          fail: 'fail',
          error: 'error',
          todo: 'todo',
          wait: 'wait',
          skip: 'skip'
      }

      @@test_index = 0

      @@group = {}
      @@preconditions = {}
      @@titles = {}
      @@descriptions = {}
      @@details = {}
      @@requires = {}
      @@conformance_supports = {}
      @@defines = {}
      @@test_metadata = {}

      @@optional = []

      @@test_id_prefixes = {}

      @@inactive = {}

      def initialize(instance, client, disable_tls_tests = false, sequence_result = nil, metadata_only = false)
        @client = client
        @instance = instance
        @client.set_bearer_token(@instance.token) unless (@client.nil? || @instance.nil? || @instance.token.nil?)
        @client.monitor_requests unless @client.nil?
        @sequence_result = sequence_result
        @disable_tls_tests = disable_tls_tests
        @test_warnings = []
        @metadata_only = metadata_only
      end

      def resume(request = nil, headers = nil, params = nil, &block)

        @params = params unless params.nil?

        @sequence_result.test_results.last.result = STATUS[:pass]

        unless request.nil?
          @sequence_result.test_results.last.request_responses << Models::RequestResponse.new(
              direction: 'inbound',
              request_method: request.request_method.downcase,
              request_url: request.url,
              request_headers: headers.to_json,
              request_payload: request.body.read
          )
        end

        @sequence_result.result = STATUS[:pass]
        @sequence_result.wait_at_endpoint = nil
        @sequence_result.redirect_to_url = nil

        @sequence_result.save!

        start(&block)
      end

      def start
        if @sequence_result.nil?
          @sequence_result = Models::SequenceResult.new(name: sequence_name, result: STATUS[:pass], testing_instance: @instance, required: !optional?, app_version: VERSION)
          @sequence_result.save!
        end

        start_at = @sequence_result.test_results.length

        methods = self.methods.grep(/_test$/).sort
        methods.each_with_index do |test_method, index|
          next if index < start_at
          @client.requests = [] unless @client.nil?
          LoggedRestClient.clear_log
          result = self.method(test_method).call()

          # Check to see if we are in headless mode and should redirect

          if result.wait_at_endpoint == 'redirect' && !@instance.standalone_launch_script.nil?
            begin
              @params = run_script(@instance.standalone_launch_script, result.redirect_to_url)
              result.result = STATUS[:pass]
            rescue => e
              result.result = STATUS[:fail]
              result.message = "Automated browser script failed: #{e}"
            end
          elsif result.wait_at_endpoint == 'launch' && !@instance.ehr_launch_script.nil?
            begin
              @params = run_script(@instance.ehr_launch_script)
              result.result = STATUS[:pass]
            rescue => e
              result.result = STATUS[:fail]
              result.message = "Automated browser script failed: #{e}"
            end
          end

          unless @client.nil?
            @client.requests.each do |req|
              result.request_responses << Models::RequestResponse.new(
                  direction: 'outbound',
                  request_method: req.request[:method],
                  request_url: req.request[:url],
                  request_headers: req.request[:headers].to_json,
                  request_payload: req.request[:payload],
                  response_code: req.response[:code],
                  response_headers: req.response[:headers].to_json,
                  response_body: req.response[:body])
            end
          end

          LoggedRestClient.requests.each do |req|
            result.request_responses << Models::RequestResponse.new(
                direction: req[:direction],
                request_method: req[:request][:method].to_s,
                request_url: req[:request][:url],
                request_headers: req[:request][:headers].to_json,
                request_payload: req[:request][:payload].to_json,
                response_code: req[:response][:code],
                response_headers: req[:response][:headers].to_json,
                response_body: req[:response][:body])
          end

          yield result if block_given?

          @sequence_result.test_results << result

          if result.result == STATUS[:wait]
            @sequence_result.redirect_to_url = result.redirect_to_url
            @sequence_result.wait_at_endpoint = result.wait_at_endpoint
            break
          end
        end

        @sequence_result.passed_count = @sequence_result.todo_count = @sequence_result.failed_count = @sequence_result.error_count = @sequence_result.skip_count = 0
        @sequence_result.result = STATUS[:pass]

        @sequence_result.test_results.each do |result|
          case result.result
          when STATUS[:pass]
            @sequence_result.passed_count += 1
          when STATUS[:todo]
            @sequence_result.todo_count += 1
          when STATUS[:fail]
            if result.required
              @sequence_result.failed_count += 1
              @sequence_result.result = result.result if @sequence_result.result != STATUS[:error]
            end
          when STATUS[:error]
            if result.required
              @sequence_result.error_count += 1
              @sequence_result.result = result.result
            end
          when STATUS[:skip]
            if result.required
              @sequence_result.skip_count += 1
              @sequence_result.result = result.result if @sequence_result.result == STATUS[:pass]
            end
          when STATUS[:wait]
            @sequence_result.result = result.result
          end
        end

        @sequence_result
      end

      def self.test_count
        self.new(nil,nil).test_count
      end

      def test_count
        self.methods.grep(/_test$/).length
      end


      def sequence_name
        self.class.sequence_name
      end

      def self.group(group = nil)
        @@group[self.sequence_name] = group unless group.nil?
        @@group[self.sequence_name] || []
      end

      def self.sequence_name
        self.name.split('::').last
      end

      def sequence_result
        @sequence_result
      end

      def self.title(title = nil)
        @@titles[self.sequence_name] = title unless title.nil?
        @@titles[self.sequence_name] || self.sequence_name
      end

      def self.description(description = nil)
        @@descriptions[self.sequence_name] = description unless description.nil?
        @@descriptions[self.sequence_name]
      end

      def self.details(details = nil)
        @@details[self.sequence_name] = details unless details.nil?
        @@details[self.sequence_name]
      end

      def self.requires(*requires)
        @@requires[self.sequence_name] = requires unless requires.empty?
        @@requires[self.sequence_name] || []
      end

      def self.conformance_supports(*supports)
        @@conformance_supports[self.sequence_name] = supports unless supports.empty?
        @@conformance_supports[self.sequence_name] || []
      end

      def self.missing_requirements(instance, recurse = false)

        return [] unless @@requires.key?(self.sequence_name)

        requires = @@requires[self.sequence_name]

        missing = requires.select { |r| instance.respond_to?(r) && instance.send(r).nil? }

        dependencies = {}
        dependencies[self] = missing.map do |requirement|
          [requirement, ordered_sequences.select{ |sequence| sequence.defines.include? requirement}]
        end

        # move this into a hash so things are duplicated.

        if(recurse)

          linked_dependencies = {}
          dependencies[self].each do |dep|
            return if linked_dependencies.has_key? dep
            dep[1].each do |seq|
              linked_dependencies.merge! seq.missing_requirements(instance, true)
            end
          end

          dependencies.merge! linked_dependencies

        else
          return dependencies[self]
        end

        dependencies

      end

      def self.variable_required_by(variable)
        ordered_sequences.select{ |sequence| sequence.requires.include? variable}
      end

      def self.variable_defined_by(variable)
        ordered_sequences.select{ |sequence| sequence.defines.include? variable}
      end

      def self.defines(*defines)
        @@defines[self.sequence_name] = defines unless defines.empty?
        @@defines[self.sequence_name] || []
      end


      def self.test_id_prefix(test_id_prefix = nil)
        @@test_id_prefixes[self.sequence_name] = test_id_prefix unless test_id_prefix.nil?
        @@test_id_prefixes[self.sequence_name]
      end

      def self.inactive
        @@inactive[self.sequence_name] = true
      end

      def self.inactive?
        @@inactive.has_key?(self.sequence_name)
      end

      def self.tests
        @@test_metadata[self.sequence_name]
      end

      def optional?
        self.class.optional?
      end

      def self.optional
        @@optional << self.sequence_name
      end

      def self.optional?
        @@optional.include?(self.sequence_name)
      end

      def self.preconditions(description, &block)
        @@preconditions[self.sequence_name] = {
            block: block,
            description: description
        }
      end

      def self.preconditions_description
        @@preconditions[self.sequence_name] && @@preconditions[self.sequence_name][:description]
      end

      def self.preconditions_met_for?(instance)

        return true unless @@preconditions.key?(self.sequence_name)

        block = @@preconditions[self.sequence_name][:block]
        self.new(instance,nil).instance_eval &block
      end

      # Defines a new test.
      #
      # name - The String name of the test
      # block - The Block test to be executed
      def self.test(name, &block)

        @@test_index += 1

        test_index = @@test_index

        test_method = "#{@@test_index.to_s.rjust(4,"0")} #{name} test".downcase.tr(' ', '_').to_sym
        @@test_metadata[self.sequence_name] ||= []
        @@test_metadata[self.sequence_name] << { name: name,
                                                 test_index: test_index,
                                                 required: true }

        test_index_in_sequence = @@test_metadata[self.sequence_name].length - 1

        wrapped = -> () do

          instance_eval &block if @metadata_only # just run the test to hit the metadata block

          @test_warnings, @links, @requires, @validates = [],[],[],[]
          result = Models::TestResult.new(test_id: @@test_metadata[self.sequence_name][test_index_in_sequence][:test_id],
                                          name: name,
                                          ref: @@test_metadata[self.sequence_name][test_index_in_sequence][:ref],
                                          required: @@test_metadata[self.sequence_name][test_index_in_sequence][:required],
                                          description: @@test_metadata[self.sequence_name][test_index_in_sequence][:description],
                                          url: @@test_metadata[self.sequence_name][test_index_in_sequence][:url],
                                          result: STATUS[:pass],
                                          test_index: test_index)
          begin

            instance_eval &block

          rescue AssertionException, ClientException => e
            result.result = STATUS[:fail]
            result.message = e.message
            result.details = e.details

          rescue TodoException => e
            result.result = STATUS[:todo]
            result.message = e.message

          rescue WaitException => e
            result.result = STATUS[:wait]
            result.wait_at_endpoint = e.endpoint

          rescue RedirectException => e
            result.result = STATUS[:wait]
            result.wait_at_endpoint = e.endpoint
            result.redirect_to_url = e.url

          rescue SkipException => e
            result.result = STATUS[:skip]
            result.message = e.message
            result.details = e.details

          rescue => e
            result.result = STATUS[:error]
            result.message = "Fatal Error: #{e.message}"
          end
          result.test_warnings = @test_warnings.map{ |w| Models::TestWarning.new(message: w)} unless @test_warnings.empty?
          result
        end

        define_method test_method, wrapped

        instance = self.new(nil, nil, nil, nil, true)
        begin
          instance.send(test_method)
        rescue MetadataException => e
        end

      end

      def metadata
        if @metadata_only
          yield
          raise MetadataException.new
        end
      end

      def id test_id
        complete_test_id = @@test_id_prefixes[self.sequence_name] + '-' + test_id
        @@test_metadata[self.sequence_name].last[:test_id] = complete_test_id
      end

      def link link
        @@test_metadata[self.sequence_name].last[:url] = link
      end

      def ref ref
        @@test_metadata[self.sequence_name].last[:ref] = requirement
      end

      def optional
        @@test_metadata[self.sequence_name].last[:required] = false
      end

      def desc description
        @@test_metadata[self.sequence_name].last[:description] = description
      end

      def todo(message = "")
        raise TodoException.new message
      end

      def skip(message = "", details = nil)
        raise SkipException.new message, details
      end

      def skip_unless(test, message = '', details = nil)
        unless test
          raise SkipException.new message, details
        end
      end

      def wait_at_endpoint(endpoint)
        raise WaitException.new endpoint
      end

      def redirect(url, endpoint)
        raise RedirectException.new url, endpoint
      end

      def warning
        begin
          yield
        rescue AssertionException => e
          @test_warnings << e.message
        end
      end

      def get_resource_by_params(klass, params = {})
        assert !params.empty?, "No params for search"
        options = {
            :search => {
                :flag => false,
                :compartment => nil,
                :parameters => params
            }
        }
        @client.search(klass, options)
      end

      def check_sort_order(entries)
        relevant_entries = entries.select{|x|x.request.try(:local_method)!='DELETE'}
        relevant_entries.map!(&:resource).map!(&:meta).compact rescue assert(false, 'Unable to find meta for resources returned by the bundle')

        relevant_entries.each_cons(2) do |left, right|
          if !left.versionId.nil? && !right.versionId.nil?
            assert (left.versionId > right.versionId), 'Result contains entries in the wrong order.'
          elsif !left.lastUpdated.nil? && !right.lastUpdated.nil?
            assert (left.lastUpdated >= right.lastUpdated), 'Result contains entries in the wrong order.'
          else
            raise AssertionException.new 'Unable to determine if entries are in the correct order -- no meta.versionId or meta.lastUpdated'
          end
        end
      end

      def validate_search_reply(klass, reply)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        entries = reply.resource.entry.select{ |entry| entry.resource.class == klass }
        assert entries.length > 0, 'No resources of this type were returned'

        if klass == FHIR::DSTU2::Patient
          assert !reply.resource.get_by_id(@instance.patient_id).nil?, 'Server returned nil patient'
          assert reply.resource.get_by_id(@instance.patient_id).equals?(@patient, ['_id', "text", "meta", "lastUpdated"]), 'Server returned wrong patient'
        elsif klass == FHIR::DSTU2::Provenance
          entries.each do |entry|
            assert (entry.resource.target && entry.resource.target.any?{|t| t.reference.include?(@instance.patient_id)}), "No target on resource matches patient requested"
          end
        elsif [FHIR::DSTU2::CarePlan, FHIR::DSTU2::Goal, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Observation, FHIR::DSTU2::Procedure, FHIR::DSTU2::DocumentReference, FHIR::DSTU2::Composition].include?(klass)
          entries.each do |entry|
            assert (entry.resource.subject && entry.resource.subject.reference.include?(@instance.patient_id)), "Subject on resource does not match patient requested"
          end
        else
          entries.each do |entry|
            assert (entry.resource.patient && entry.resource.patient.reference.include?(@instance.patient_id)), "Patient on resource does not match patient requested"
          end
        end
      end

      def save_resource_ids_in_bundle(klass, reply)
        return if reply.try(:resource).try(:entry).nil?

        entries = reply.resource.entry.select{ |entry| entry.resource.class == klass }

        entries.each do |entry|
          @instance.post_resource_references(resource_type: klass.name.split(':').last,
                                             resource_id: entry.resource.id)
        end
      end

      def validate_read_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        read_response = @client.read(klass, id)
        assert_response_ok read_response
        assert !read_response.resource.nil?, "Expected valid #{klass} resource to be present"
        assert read_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
      end

      def validate_history_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        history_response = @client.resource_instance_history(klass, id)
        assert_response_ok history_response
        assert_bundle_response history_response
        assert_equal "history", history_response.try(:resource).try(:type)
        entries = history_response.try(:resource).try(:entry)
        assert entries, 'No bundle entries returned'
        assert entries.try(:length) > 0, 'No resources of this type were returned'
        check_sort_order entries
      end

      def validate_vread_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        version_id = resource.try(:meta).try(:versionId)
        assert !version_id.nil?, "#{klass} version_id not returned"
        vread_response = @client.vread(klass, id, version_id)
        assert_response_ok vread_response
        assert !vread_response.resource.nil?, "Expected valid #{klass} resource to be present"
        assert vread_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
      end

      attr_accessor :profiles_encountered
      attr_accessor :profiles_failed

      def test_resources_against_profile(resource_type, specified_profile=nil)
        @profiles_encountered = [] unless @profiles_encountered
        @profiles_failed = {} unless @profiles_failed

        all_errors = []

        resources = @instance.resource_references.select{|r| r.resource_type == resource_type}
        skip("Skip profile validation since no #{resource_type} resources found for Patient.") if resources.empty?

        @instance.resource_references.select{|r| r.resource_type == resource_type}.map(&:resource_id).each do |resource_id|

          resource_response = @client.read("FHIR::DSTU2::#{resource_type}", resource_id)
          assert_response_ok resource_response
          resource = resource_response.resource
          assert resource.is_a?("FHIR::DSTU2::#{resource_type}".constantize), "Expected resource to be of type #{resource_type}"

          p = Inferno::ValidationUtil.guess_profile(resource)
          if specified_profile
            next unless p.url == specified_profile
          end
          if p
            @profiles_encountered << p.url
            @profiles_encountered.uniq!
            errors = p.validate_resource(resource)
            unless errors.empty?
              errors.map!{|e| "#{resource_type}/#{resource_id}: #{e}"}
              @profiles_failed[p.url] = [] unless @profiles_failed[p.url]
              @profiles_failed[p.url].concat(errors)
            end
            all_errors.concat(errors)
          else
            errors = entry.resource.validate
            all_errors.concat(errors.values)
          end
        end
        # TODO
        # bundle = client.next_bundle
        assert(all_errors.empty?, all_errors.join("<br/>\n"))
      end



      # This is intended to be called on SequenceBase
      # There is a test to ensure that this doesn't fall out of date
      def self.ordered_sequences
        self.sequences_groups.map{|h| h[:sequences]}.flatten
      end

      def self.sequences_overview
        %(
          Background
        )

      end

      def self.sequences_groups
        [{
          name: 'Discovery',
          overview: %(
            This is a description of the discovery group
          ),
          sequences: [ConformanceSequence],
          run_all: false
        },
        {
          name: 'Authentication and Authorization',
          overview: %(



          ),
          sequences: [
            DynamicRegistrationSequence,
            ManualRegistrationSequence,
            StandaloneLaunchSequence,
            EHRLaunchSequence,
            OpenIDConnectSequence,
            TokenRefreshSequence
          ],
          run_all: false
        },
        {
          name: 'Argonaut Profile Conformance',
          overview: %(



          ),
          sequences: [
            ArgonautPatientSequence,
            ArgonautAllergyIntoleranceSequence,
            ArgonautCarePlanSequence,
            ArgonautCareTeamSequence,
            ArgonautConditionSequence,
            ArgonautDeviceSequence,
            ArgonautDiagnosticReportSequence,
            ArgonautObservationSequence,
            ArgonautGoalSequence,
            ArgonautImmunizationSequence,
            ArgonautMedicationStatementSequence,
            ArgonautMedicationOrderSequence,
            ArgonautProcedureSequence,
            ArgonautSmokingStatusSequence,
            ArgonautVitalSignsSequence
          ],
          run_all: true
        }]


      end

    end

    Dir[File.join(__dir__, 'sequences', '*_sequence.rb')].each { |file| require file }

  end
end

