# frozen_string_literal: true

require_relative 'utils/assertions'
require_relative 'utils/skip_helpers'
require_relative 'ext/fhir_client'
require_relative 'utils/logged_rest_client'
require_relative 'utils/exceptions'
require_relative 'utils/validation'
require_relative 'utils/walk'
require_relative 'utils/web_driver'
require_relative 'utils/terminology'
require_relative 'utils/result_statuses'
require_relative 'utils/search_validation'
require_relative 'models/testing_instance'
require_relative 'models/inferno_test'
require_relative 'utils/hl7_validator'

require 'bloomer'
require 'bloomer/msgpackable'
require 'json'

module Inferno
  module Sequence
    Inferno::Terminology.load_validators

    class SequenceBase
      include Assertions
      include SkipHelpers
      include SearchValidationUtil
      include Inferno::WebDriver

      @@test_index = 0

      @@group = {}
      @@preconditions = {}
      @@titles = {}
      @@descriptions = {}
      @@details = {}
      @@requires = {}
      @@conformance_supports = {}
      @@defines = {}
      @@versions = {}

      @@optional = []
      @@show_uris = []
      @@show_bulk_registration_info = []
      @@delayed_sequences = []

      @@test_id_prefixes = {}

      attr_accessor :profiles_encountered
      attr_accessor :profiles_failed
      attr_accessor :sequence_result

      delegate :versioned_resource_class, to: :@client
      delegate :versioned_conformance_class, to: :@instance
      delegate :save_resource_ids_in_bundle, to: :@instance
      delegate :save_resource_references, to: :@instance

      def initialize(instance, client, disable_tls_tests = false, sequence_result = nil)
        @client = client
        @instance = instance
        @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
        @client&.monitor_requests
        @sequence_result = sequence_result
        @disable_tls_tests = disable_tls_tests
        @test_warnings = []
        @information_messages = []
      end

      def resume(request = nil, headers = nil, params = nil, fail_message = nil, &block)
        @params = params unless params.nil?

        sequence_result.test_results.last.pass!

        if fail_message.present?
          sequence_result.test_results.last.fail!
          sequence_result.test_results.last.message = fail_message
        end

        unless request.nil?
          sequence_result.test_results.last.request_responses << Models::RequestResponse.new(
            direction: 'inbound',
            request_method: request.request_method.downcase,
            request_url: request.url,
            request_headers: headers.to_json,
            request_payload: request.body.read,
            instance_id: @instance.id,
            timestamp: DateTime.now
          )
        end

        sequence_result.pass!
        sequence_result.wait_at_endpoint = nil
        sequence_result.redirect_to_url = nil

        sequence_result.save!

        start(&block)
      end

      def start(test_set_id = nil, test_case_id = nil, &block)
        if sequence_result.nil?
          self.sequence_result = Models::SequenceResult.new(
            name: sequence_name,
            result: ResultStatuses::PASS,
            testing_instance: @instance,
            required: !optional?,
            test_set_id: test_set_id,
            test_case_id: test_case_id,
            app_version: VERSION
          )
          sequence_result.save!
        end

        start_at = sequence_result.result_count

        load_input_params(sequence_name)

        output_results = save_output(sequence_name)

        run_tests(tests[start_at..-1], &block)

        update_output(sequence_name, output_results)

        sequence_result.tap do |result|
          result.output_results = output_results.to_json if output_results.present?

          result.reset!
          result.pass!

          result.update_result_counts
        end
      end

      def load_input_params(sequence_name)
        input_parameters = {}
        @@requires[sequence_name]
          &.select { |requirement| @instance.respond_to? requirement }
          &.each do |requirement|
            input_value = @instance.send(requirement).to_s
            input_value = 'none' if input_value.empty?
            input_parameters[requirement.to_sym] = input_value
          end
        sequence_result.input_params = input_parameters.to_json
      end

      def save_output(sequence_name)
        {}.tap do |output_results|
          @@defines[sequence_name]
            &.select { |output| @instance.respond_to? output }
            &.each do |output|
              output_value = @instance.send(output).to_s
              output_value = 'none' if output_value.empty?
              output_results[output.to_sym] = { original: output_value }
            end
        end
      end

      def update_output(sequence_name, output_results)
        @@defines[sequence_name]
          &.select { |output| @instance.respond_to? output }
          &.each do |output|
            output_value = @instance.send(output).to_s
            output_value = 'none' if output_value.empty?
            output_results[output.to_sym][:updated] = output_value
          end
      end

      def run_tests(inferno_tests)
        inferno_tests.each do |inferno_test|
          @client.requests = [] unless @client.nil?
          LoggedRestClient.clear_log
          result = instance_exec(&wrap_test(inferno_test))

          # Check to see if we are in headless mode and should redirect

          if result.wait_at_endpoint == 'redirect' && !@instance.standalone_launch_script.nil?
            begin
              @params = run_script(@instance.standalone_launch_script, result.redirect_to_url)
              result.pass!
            rescue StandardError => e
              result.fail!
              result.message = "Automated browser script failed: #{e}"
            end
          elsif result.wait_at_endpoint == 'launch' && !@instance.ehr_launch_script.nil?
            begin
              @params = run_script(@instance.ehr_launch_script)
              result.pass!
            rescue StandardError => e
              result.fail!
              result.message = "Automated browser script failed: #{e}"
            end
          end

          @client&.requests&.each do |req|
            result.request_responses << Models::RequestResponse.from_request(req, @instance.id, 'outbound')
          end

          LoggedRestClient.requests.each do |req|
            result.request_responses << Models::RequestResponse.from_request(OpenStruct.new(req), @instance.id)
          end

          yield result if block_given?

          sequence_result.test_results << result

          next unless result.wait?

          sequence_result.redirect_to_url = result.redirect_to_url
          sequence_result.expect_redirect_failure = result.expect_redirect_failure
          sequence_result.wait_at_endpoint = result.wait_at_endpoint
          break
        end
      end

      def self.test_count(inferno_module = nil)
        tests(inferno_module).length
      end

      def test_count(inferno_module = @instance.module)
        tests(inferno_module).length
      end

      def sequence_name
        self.class.sequence_name
      end

      def self.group(group = nil)
        @@group[sequence_name] = group unless group.nil?
        @@group[sequence_name] || []
      end

      def self.sequence_name
        name.demodulize
      end

      def self.title(title = nil)
        @@titles[sequence_name] = title unless title.nil?
        @@titles[sequence_name] || sequence_name
      end

      def self.description(description = nil)
        @@descriptions[sequence_name] = description unless description.nil?
        @@descriptions[sequence_name]
      end

      def self.details(details = nil)
        @@details[sequence_name] = details unless details.nil?
        @@details[sequence_name]
      end

      def self.requires(*requires)
        @@requires[sequence_name] = requires unless requires.empty?
        @@requires[sequence_name] || []
      end

      def self.conformance_supports(*supports)
        @@conformance_supports[sequence_name] = supports unless supports.empty?
        @@conformance_supports[sequence_name] || []
      end

      def self.resources_to_test
        conformance_supports.map(&:to_s)
      end

      def self.versions(*versions)
        @@versions[sequence_name] = versions unless versions.empty?
        @@versions[sequence_name] || FHIR::VERSIONS
      end

      def self.delayed_sequence
        @@delayed_sequences << sequence_name
      end

      def self.missing_requirements(instance, recurse = false)
        return [] unless @@requires.key?(sequence_name)

        requires = @@requires[sequence_name]

        missing = requires.select { |r| instance.respond_to?(r) && instance.send(r).nil? }

        dependencies = {}
        dependencies[self] = missing.map do |requirement|
          [requirement, instance.sequences.select { |sequence| sequence.defines.include? requirement }]
        end

        # move this into a hash so things are duplicated.

        return dependencies[self] unless recurse

        linked_dependencies = {}
        dependencies[self].each do |dep|
          return if linked_dependencies.key? dep

          dep[1].each do |seq|
            linked_dependencies.merge! seq.missing_requirements(instance, true)
          end
        end

        dependencies.merge! linked_dependencies

        dependencies
      end

      def self.defines(*defines)
        @@defines[sequence_name] = defines unless defines.empty?
        @@defines[sequence_name] || []
      end

      def self.test_id_prefix(test_id_prefix = nil)
        @@test_id_prefixes[sequence_name] = test_id_prefix unless test_id_prefix.nil?
        @@test_id_prefixes[sequence_name]
      end

      def self.all_tests
        @all_tests ||= []
      end

      def self.tests(inferno_module = nil)
        return all_tests unless inferno_module&.hide_optional

        all_tests.select(&:required?)
      end

      def tests(inferno_module = @instance.module)
        self.class.tests(inferno_module)
      end

      def self.[](key)
        tests.find { |test| test.key == key }
      end

      def optional?
        self.class.optional?
      end

      def self.optional
        @@optional << sequence_name
      end

      def self.optional?
        @@optional.include?(sequence_name)
      end

      def self.show_uris
        @@show_uris << sequence_name
      end

      def self.show_uris?
        @@show_uris.include?(sequence_name)
      end

      def self.show_bulk_registration_info
        @@show_bulk_registration_info << sequence_name
      end

      def self.show_bulk_registration_info?
        @@show_bulk_registration_info.include?(sequence_name)
      end

      def self.preconditions(description, &block)
        @@preconditions[sequence_name] = {
          block: block,
          description: description
        }
      end

      def self.preconditions_description
        @@preconditions[sequence_name] && @@preconditions[sequence_name][:description]
      end

      def self.preconditions_met_for?(instance)
        return true unless @@preconditions.key?(sequence_name)

        block = @@preconditions[sequence_name][:block]
        new(instance, nil).instance_eval(&block)
      end

      # this must be called to ensure that the child class is referenced in self.sequence_name
      def self.extends_sequence(klass)
        all_tests.concat(klass.all_tests)
      end

      # Defines a new test.
      #
      # name - The String name of the test
      # block - The Block test to be executed
      def self.test(name, &block)
        @@test_index += 1
        new_test = InfernoTest.new(name, @@test_index, @@test_id_prefixes[sequence_name], &block)

        if new_test.key.present? && all_tests.any? { |test| test.key == new_test.key }
          raise InvalidKeyException, "Duplicate test key #{new_test.key.inspect} in #{self.name.demodulize}"
        end

        all_tests << new_test
      end

      def wrap_test(test)
        lambda do
          @test_warnings = []
          @information_messages = []
          Models::TestResult.new(
            test_id: test.id,
            name: test.name,
            ref: test.ref,
            required: !test.optional?,
            description: test.description,
            url: test.link,
            versions: test.versions.join(','),
            result: ResultStatuses::PASS,
            test_index: test.index
          ).tap do |result|
            begin
              skip_unless(@instance.fhir_version_match?(self.class.versions), 'This test does not run with this FHIR version')
              Inferno.logger.info "Starting Test: #{test.id} [#{test.name}]"
              run_test(test)
            rescue StandardError => e
              if e.respond_to? :update_result
                e.update_result(result)
              else
                Inferno.logger.error "Fatal Error: #{e.message}"
                Inferno.logger.error e.class.name
                Inferno.logger.error e.backtrace
                result.error!
                result.message = "Fatal Error: #{e.message}"
              end
            end

            result.test_warnings = @test_warnings.map { |w| Models::TestWarning.new(message: w) }
            result.information_messages = @information_messages.map { |m| Models::InformationMessage.new(message: m) }
            Inferno.logger.info "Finished Test: #{test.id} [#{result.result}]"
          end
        end
      end

      def run_test(test)
        instance_eval(&test.test_block)
      end

      # Metadata loading is handled by InfernoTest
      def metadata; end

      def todo(message = '')
        raise TodoException, message
      end

      def pass(message = '')
        raise PassException, message
      end

      def omit(message = '')
        raise OmitException, message
      end

      def skip(message = '', details = nil)
        raise SkipException.new message, details
      end

      def skip_unless(test, message = '', details = nil)
        raise SkipException.new message, details unless test
      end

      def skip_if(test, message = '', details = nil)
        raise SkipException.new message, details if test
      end

      def wait_at_endpoint(endpoint)
        raise WaitException, endpoint
      end

      def redirect(url, endpoint, expect_failure = false)
        raise RedirectException.new url, endpoint, expect_failure
      end

      def warning
        yield
      rescue AssertionException => e
        @test_warnings << e.message
      end

      def get_resource_by_params(klass, params)
        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        @client.search(klass, options)
      end

      def validate_sort_order(entries)
        relevant_entries = entries.reject { |entry| entry.request&.local_method == 'DELETE' }
        begin
          relevant_entries.map!(&:resource).map!(&:meta).compact
        rescue StandardError
          assert(false, 'Unable to find meta for resources returned by the bundle')
        end

        relevant_entries.each_cons(2) do |left, right|
          left_version, right_version =
            if left.versionId.present? && right.versionId.present?
              [left.versionId, right.versionId]
            elsif left.lastUpdated.present? && right.lastUpdated.present?
              [left.lastUpdated, right.lastUpdated]
            else
              raise AssertionException, 'Unable to determine if entries are in the correct order -- no meta.versionId or meta.lastUpdated'
            end

          assert (left_version > right_version), 'Result contains entries in the wrong order.'
        end
      end

      def validate_resource_item(_resource, _property, _value)
        assert false, 'Could not validate resource'
      end

      def validate_search_reply(klass, reply, search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        entries = fetch_all_bundled_resources(reply).select { |entry| entry.class == klass }
        validate_reply_entries(entries, search_params)
        assert entries.present?, 'No resources of this type were returned'
      end

      def validate_reply_entries(resources, search_params)
        resources.each do |resource|
          # This checks to see if the base resource conforms to the specification
          # It does not validate any profiles.
          resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
          assert resource_validation_errors[:errors].empty?, "Invalid #{resource.resourceType}: #{resource_validation_errors[:errors].join("\n* ")}"

          search_params.each do |key, value|
            validate_resource_item(resource, key.to_s, value)
          end
        end
      end

      def validate_read_reply(resource, klass, reply_handler = nil)
        class_name = klass.name.demodulize
        assert !resource.nil?, "No #{class_name} resources available from search."
        if resource.is_a? versioned_resource_class('Reference')
          read_response = resource.read
          id = resource.reference.split('/').last
        else
          id = resource&.id
          assert !id.nil?, "#{class_name} id not returned"
          read_response = @client.read(klass, id)
          assert_response_ok read_response
          reply_handler&.call(read_response)
          read_response = read_response.resource
        end
        assert !read_response.nil?, "Expected #{class_name} resource to be present."
        assert read_response.is_a?(klass), "Expected resource to be of type #{class_name}."
        assert read_response.id.present? && read_response.id == id, "Expected resource to contain id: #{id}"
        read_response
      end

      def validate_history_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.demodulize} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        history_response = @client.resource_instance_history(klass, id)
        assert_response_ok history_response
        assert_bundle_response history_response
        assert_equal 'history', history_response.try(:resource).try(:type)
        entries = history_response.try(:resource).try(:entry)
        assert entries, 'No bundle entries returned'
        assert entries.try(:length).positive?, 'No resources of this type were returned'
        validate_sort_order entries
      end

      def validate_vread_reply(resource, klass)
        assert !resource.nil?, "No #{klass.name.demodulize} resources available from search."
        id = resource.try(:id)
        assert !id.nil?, "#{klass} id not returned"
        version_id = resource.try(:meta).try(:versionId)
        assert !version_id.nil?, "#{klass} version_id not returned"
        vread_response = @client.vread(klass, id, version_id)
        assert_response_ok vread_response
        assert !vread_response.resource.nil?, "Expected valid #{klass} resource to be present"
        assert vread_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
      end

      def validate_resource(resource_type, resource, profile)
        resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, profile.url)

        errors = resource_validation_errors[:errors]
        errors.concat(yield resource) if block_given?

        @test_warnings.concat resource_validation_errors[:warnings]
        @information_messages.concat resource_validation_errors[:information]

        errors.map! { |e| "#{resource_type}/#{resource.id}: #{e}" }
        @profiles_failed[profile.url].concat(errors) unless errors.empty?
        errors
      end

      def fetch_resource(resource_type, resource_id)
        response = @client.read(versioned_resource_class(resource_type), resource_id)
        assert_response_ok response
        resource = response.resource
        assert resource.is_a?(versioned_resource_class(resource_type)), "Expected resource to be of type #{resource_type}"
        resource
      end

      def test_resources(resource_type, &block)
        references = @instance.resource_references.all(resource_type: resource_type)
        skip_if(
          references.empty?,
          "Skip profile validation since no #{resource_type} resources found for Patient."
        )

        errors = references.map(&:resource_id).flat_map do |resource_id|
          resource = fetch_resource(resource_type, resource_id)
          p = Inferno::ValidationUtil.guess_profile(resource, @instance.fhir_version.to_sym)
          if p
            @profiles_encountered << p.url
            validate_resource(resource_type, resource, p, &block)
          else
            warn { assert false, 'No profiles found for this Resource' }
            issues = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
            issues[:errors]
          end
        end

        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      def test_resource_collection(resource_type, resources)
        errors = resources.flat_map do |resource|
          p = Inferno::ValidationUtil.guess_profile(resource, @instance.fhir_version.to_sym)
          if p
            @profiles_encountered << p.url
            validate_resource(resource_type, resource, p)
          else
            warn { assert false, 'No profiles found for this Resource' }
            issues = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
            issues[:errors]
          end
        end

        assert(errors.empty?, errors.join("<br/>\n"))
      end

      def test_resources_against_profile(resource_type, specified_profile = nil, &block)
        @profiles_encountered ||= Set.new
        @profiles_failed ||= Hash.new { |hash, key| hash[key] = [] }

        return test_resources(resource_type, &block) if specified_profile.blank?

        profile = Inferno::ValidationUtil::DEFINITIONS[specified_profile]
        skip_if(
          profile.blank?,
          "Skip profile validation since profile #{specified_profile} is unknown."
        )

        references = @instance.resource_references.all(profile: specified_profile)
        resources =
          if references.present?
            references.map(&:resource_id).map do |resource_id|
              fetch_resource(resource_type, resource_id)
            end
          else
            @instance.resource_references
              .all(resource_type: resource_type)
              .map { |reference| fetch_resource(resource_type, reference.resource_id) }
              .select { |resource| resource.meta&.profile&.include? specified_profile }
          end

        skip_if(
          resources.blank?,
          "Skip profile validation since no #{resource_type} resources conforming to the #{specified_profile} profile found for Patient."
        )

        @profiles_encountered << profile.url

        errors = resources.flat_map do |resource|
          validate_resource(resource_type, resource, profile, &block)
        end

        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      # Set max_resolutions in a single sequence to a large number by default
      def validate_reference_resolutions(resource, resolved_references = Set.new, max_resolutions = 1_000_000)
        problems = []

        walk_resource(resource) do |value, meta, path|
          next if meta['type'] != 'Reference'
          next if value.reference.blank?
          next if resolved_references.include?(value.reference)
          break if resolved_references.length > max_resolutions

          begin
            # Should potentially update valid? method in fhir_dstu2_models
            # to check for this type of thing
            # e.g. "patient/54520" is invalid (fhir_client resource_class method would expect "Patient/54520")
            if value.relative?
              begin
                value.resource_class
              rescue NameError
                problems << "#{path} has invalid resource type in reference: #{value.type}"
                next
              end
            end
            value.read
            resolved_references.add(value.reference)
          rescue ClientException => e
            problems << "#{path} did not resolve: #{e}"
          end
        end

        Inferno.logger.info "Surpassed the maximum reference resolutions: #{max_resolutions}" if resolved_references.length > max_resolutions

        assert(problems.empty?, "\n* " + problems.join("\n* "))
      end

      def check_resource_against_profile(resource, resource_type, specified_profile = nil)
        assert resource.is_a?("FHIR::DSTU2::#{resource_type}".constantize),
               "Expected resource to be of type #{resource_type}"

        p = Inferno::ValidationUtil.guess_profile(resource, @instance.fhir_version.to_sym)
        if specified_profile
          return unless p.url == specified_profile
        end
        if p
          @profiles_encountered << p.url
          errors = validate_resource(resource_type, resource, p)
        else
          resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(entry.resource, versioned_resource_class)
          errors = resource_validation_errors[:errors]
        end
        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      def fetch_all_bundled_resources(reply, reply_handler = nil)
        page_count = 1
        resources = []
        bundle = reply.resource
        until bundle.nil? || page_count == 20
          resources += bundle&.entry&.map { |entry| entry&.resource }
          next_bundle_link = bundle&.link&.find { |link| link.relation == 'next' }&.url
          reply_handler&.call(reply)
          break if next_bundle_link.blank?

          reply = @client.raw_read_url(next_bundle_link)
          error_message = "Could not resolve next bundle. #{next_bundle_link}"
          assert_response_ok(reply, error_message)
          assert_valid_json(reply.body, error_message)

          bundle = FHIR.from_contents(reply.body)

          page_count += 1
        end
        resources
      end
    end

    Dir.glob(File.join(__dir__, '..', 'modules', '**', '*_sequence.rb')).sort.each { |file| require file }
  end
end
