# frozen_string_literal: true

module Inferno
  module Sequence
    class SmartSchedulingLinksBasicSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'SMART Scheduling Links Basic Test'
      description 'Retrieve and validate resources from a SMART Scheduling Links schedule publisher'
      details %(
      )
      test_id_prefix 'SLB'
      requires :manifest_url, :manifest_since, :custom_header

      MAX_RECENT_LINE_SIZE = 500
      SPEC_URL = 'https://github.com/smart-on-fhir/smart-scheduling-links/blob/master/specification.md'

      SCHEDULING_URIS = {
        "Address": 'http://fhir-registry.smarthealthit.org/StructureDefinition/vaccine-location-address',
        "Location": 'http://fhir-registry.smarthealthit.org/StructureDefinition/vaccine-location',
        "Schedule": 'http://fhir-registry.smarthealthit.org/StructureDefinition/vaccine-schedule',
        "Slot": 'http://fhir-registry.smarthealthit.org/StructureDefinition/vaccine-slot'
      }.freeze

      def test_output_against_profile(klass,
                                      profile_definitions,
                                      output, &block)

        profile_definitions ||= []
        bulk_lines_to_validate = nil
        skip 'Bulk Data Server response does not have output data' unless output.present?

        lines_to_validate_parameter = get_lines_to_validate(bulk_lines_to_validate)

        file_list = output.find_all { |item| item['type'] == klass }

        omit_or_skip_empty_resources(klass) if file_list.empty?

        validate_all = lines_to_validate_parameter[:validate_all]
        lines_to_validate = lines_to_validate_parameter[:lines_to_validate]

        omit 'Validate has been omitted because line_to_validate is 0' if !validate_all && lines_to_validate.zero? && klass != 'Patient'

        success_count = 0

        file_list.each do |file|
          success_count += check_file_request(file, klass, validate_all, lines_to_validate, profile_definitions, &block)
        end

        omit_or_skip_empty_resources(klass) if success_count.zero? && (validate_all || lines_to_validate.positive?)

        success_count
      end

      def omit_or_skip_empty_resources(klass)
        omit "No #{klass} resources provided, and #{klass} resources are optional." if OMIT_KLASS.include?(klass)
        skip "Bulk data export did not provide any #{klass} resources."
      end

      def get_lines_to_validate(input)
        if input.nil? || input.strip.empty?
          validate_all = true
          lines_to_validate = 0
        else
          lines_to_validate = input.to_i
        end

        {
          validate_all: validate_all,
          lines_to_validate: lines_to_validate
        }
      end

      def check_file_request(file, klass, validate_all = true, lines_to_validate = 0, profile_definitions = [])
        headers = { accept: 'application/fhir+ndjson' }
        headers['Authorization'] = "Bearer #{@instance.bulk_access_token}" if @requires_access_token && @instance.bulk_access_token.present?
        headers[@instance.custom_header.split(':').first.strip] = @instance.custom_header.split(':')[1].strip if @instance.custom_header&.include?(':')

        line_count = 0
        validation_error_collection = {}
        line_collection = []

        request_for_log = {
          method: 'GET',
          url: file['url'],
          headers: headers
        }

        response_for_log = {
          body: String.new
        }

        streamed_ndjson_get(file['url'], headers) do |response, resource|
          # Do not trigger warning because it is unclear if this needs to technically follow the bulk data igg,
          # warning do
          #   assert response.header['Content-Type'] == 'application/fhir+ndjson', "Content type must be 'application/fhir+ndjson' but is '#{response.header['Content-type']}'"
          # end

          break if !validate_all && line_count >= lines_to_validate

          response_for_log[:code] = response.code unless response_for_log.key?(:code)
          response_for_log[:headers] = response.header unless response_for_log.key?(:headers)
          line_collection << resource if line_count < MAX_RECENT_LINE_SIZE

          line_count += 1

          resource = versioned_resource_class.from_contents(resource)
          resource_type = resource.class.name.demodulize
          assert resource_type == klass, "Resource type \"#{resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{klass}\")"

          # debuging
          # resource.address.line = nil if resource.id == '1' && resource.resourceType == 'Location'

          yield(resource)

          p = guess_profile(resource, @instance.fhir_version.to_sym)

          resource_validation_errors = validate(klass, resource, p)

          process_profile_definition(profile_definitions, p, resource, resource_validation_errors)

          # Remove warnings if using internal FHIRModelsValidator. FHIRModelsValidator has an issue with FluentPath.
          resource_validation_errors = [] if resource_validation_errors[:errors].empty? &&
                                             (Inferno::RESOURCE_VALIDATOR.is_a?(Inferno::FHIRModelsValidator) ||
                                             (resource_validation_errors[:warnings].empty? && resource_validation_errors[:information].empty?))

          validation_error_collection[line_count] = resource_validation_errors unless resource_validation_errors.empty?
        end

        unless validate_all
          response_for_log[:body] = line_collection.join
          LoggedRestClient.record_response(request_for_log, response_for_log)
        end

        process_validation_errors(validation_error_collection, line_count, klass)

        assert_must_supports_found(profile_definitions) if line_count.positive?

        if file.key?('count') && validate_all
          warning do
            assert file['count'].to_s == line_count.to_s, "Count in status output (#{file['count']}) did not match actual number of resources returned (#{line_count})"
          end
        end

        line_count
      end

      def validate(klass, resource, profile)
        if profile && @instance.fhir_version == 'r4'
          resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, profile.url)

          # US Core 3.1.1 has both Reference(US Core Encounter) and Reference(Encounter).
          # Bulk Data validation expects at least one Encounter validates to the with US Core Encounter profile, but not all.
          if klass == 'Encounter'
            if resource_validation_errors[:errors].empty?
              @us_core_encounter_count += 1
            else
              resource_validation_errors = validate(klass, resource, nil)
            end
          end
        else
          warn { assert false, 'No profiles found for this Resource' }
          resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
        end

        resource_validation_errors
      end

      def guess_profile(resource, version)
        definitions = Inferno::ValidationUtil.definitions
        # if the profile is given, we don't need to guess
        if resource&.meta&.profile&.present?
          resource.meta.profile.each do |uri|
            return definitions[uri] if definitions[uri]
          end
        end

        return if resource.blank?

        # If we're looking at a resource of one of the types specified in the IG, we probably want to use the profile:
        resource_type = resource.resourceType.to_sym
        return definitions[SCHEDULING_URIS[resource_type]] if SCHEDULING_URIS[resource_type]

        # Otherwise, fall back to the base profile finder
        Inferno::ValidationUtil.guess_profile(resource, version)
      end

      def process_profile_definition(profile_definitions, profile, resource, resource_validation_errors)
        return unless profile.present? && profile_definitions.present?

        if profile_definitions.length > 1 && profile
          profile_must_support = profile_definitions.find { |profile_definition| profile_definition[:profile] == profile.url }
          must_support_info = profile_must_support.present? ? profile_must_support[:must_support_info] : nil
          binding_info = profile_must_support.present? ? profile_must_support[:binding_info] : nil
        else
          must_support_info = profile_definitions.first[:must_support_info]
          binding_info = profile_definitions.first[:binding_info]
        end

        process_must_support(must_support_info, resource) if must_support_info.present?

        return unless binding_info.present?

        terminology_validation_errors = validate_bindings(binding_info, Array(resource))
        resource_validation_errors[:errors].concat(terminology_validation_errors[:errors])
        resource_validation_errors[:warnings].concat(terminology_validation_errors[:warnings])
      end

      def process_must_support(must_support_info, resource)
        return unless must_support_info.present?

        must_support_info[:elements].reject! do |ms_element|
          value_found = resolve_element_from_path(resource, ms_element[:path]) do |value|
            value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
            (value_without_extensions.present? || value_without_extensions == false) && (ms_element[:fixed_value].blank? || value == ms_element[:fixed_value])
          end

          value_found.present? || value_found == false
        end

        must_support_info[:extensions].reject! do |ms_extension|
          resource.extension.any? { |extension| extension.url == ms_extension[:url] }
        end

        must_support_info[:slices].reject! do |ms_slice|
          find_slice(resource, ms_slice[:path], ms_slice[:discriminator])
        end
      end

      def validate_bindings(bindings, resources)
        return unless bindings.present?

        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        validation_errors = { errors: [], warnings: [] }
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, resources)
          rescue Inferno::Terminology::UnknownValueSetException => e
            validation_errors[:warnings] << e.message
            invalid_bindings = []
          end
          invalid_bindings.each { |invalid| invalid_binding_resources << "#{invalid[:resource]&.resourceType}/#{invalid[:resource].id}" }
          invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def) })
        end

        unless invalid_binding_messages.blank?
          validation_errors[:errors] << "#{invalid_binding_messages.count} invalid required #{'binding'.pluralize(invalid_binding_messages.count)}" \
            " found in #{invalid_binding_resources.count} #{'resource'.pluralize(invalid_binding_resources.count)}: " \
            "#{invalid_binding_messages.join('. ')}"
          return validation_errors
        end

        bindings.select { |binding_def| binding_def[:strength] == 'extensible' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, resources)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), resources)
              binding_def_new = binding_def.except(:system)
            end
          rescue Inferno::Terminology::UnknownValueSetException, Inferno::Terminology::ValueSet::UnknownCodeSystemException => e
            validation_errors[:warnings] << e.message
            invalid_bindings = []
          end

          validation_errors[:warnings].concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def_new) })
        end

        validation_errors
      end

      def process_validation_errors(validation_error_collection, line_count, klass)
        error_count = 0
        first_error = String.new
        first_warning = []

        validation_error_collection.each do |line_number, resource_validation_errors|
          unless resource_validation_errors[:errors].empty?
            error_count += 1
            first_error = "The first failed is line ##{line_number}:\n\n* #{resource_validation_errors[:errors].join("\n* ")}" if first_error.empty?
          end

          if first_warning.empty? && resource_validation_errors[:warnings].count.positive?
            first_warning.concat(resource_validation_errors[:warnings].map { |e| "Line ##{line_number}: #{e}" })
          end

          @information_messages.concat(resource_validation_errors[:information].map { |e| "Line ##{line_number}: #{e}" })
        end

        @test_warnings.concat(first_warning)
        assert error_count.zero?, "#{error_count} / #{line_count} #{klass} resources failed profile validation. #{first_error}"
      end

      def assert_must_supports_found(profile_definitions)
        profile_definitions.each do |must_support|
          error_string = "Could not verify presence#{' for profile ' + must_support[:profile] if must_support[:profile].present?} of the following must support %s: %s"
          missing_must_supports = must_support[:must_support_info]

          missing_elements_list = missing_must_supports[:elements].map { |el| "#{el[:path]}#{': ' + el[:fixed_value] if el[:fixed_value].present?}" }
          skip_if missing_elements_list.present?, format(error_string, 'elements', missing_elements_list.join(', '))

          missing_slices_list = missing_must_supports[:slices].map { |slice| slice[:name] }
          skip_if missing_slices_list.present?, format(error_string, 'slices', missing_slices_list.join(', '))

          missing_extensions_list = missing_must_supports[:extensions].map { |extension| extension[:id] }
          skip_if missing_extensions_list.present?, format(error_string, 'extensions', missing_extensions_list.join(', '))
        end
      end

      def log_and_reraise_if_error(request, response, truncated)
        yield
      rescue StandardError
        response[:body] = "NOTE: RESPONSE TRUNCATED\nINFERNO ONLY DISPLAYS FIRST #{MAX_RECENT_LINE_SIZE} LINES\n\n#{response[:body]}" if truncated
        LoggedRestClient.record_response(request, response)
        raise
      end

      def streamed_ndjson_get(url, headers)
        # We don't want to keep a huge log of everything that came through,
        # but we also want to show up to a reasonable number.
        recent_lines = []
        line_count = 0

        next_block = String.new

        request_for_log = {
          method: 'GET',
          url: url,
          headers: headers
        }

        response_block = proc { |response|
          response.read_body do |chunk|
            next_block << chunk
            resource_list = next_block.lines

            response_for_log = {
              code: response.code,
              headers: response.header,
              body: String.new,
              truncated: false
            }

            # Skip processing the last line since the it may not be complete (still appending from stream)
            next_block = resource_list.pop
            next_block = String.new if next_block.nil?

            resource_list.each do |resource|
              # NDJSON does not specify that empty lines are NOT allowed.
              # So just skip an empty line.
              next if resource.nil? || resource.strip.empty?

              recent_lines << resource if line_count < MAX_RECENT_LINE_SIZE
              line_count += 1

              response_for_log[:body] = recent_lines.join
              log_and_reraise_if_error(request_for_log, response_for_log, line_count > MAX_RECENT_LINE_SIZE) do
                yield(response, resource)
              end
            end
          end
        }

        response = RestClient::Request.execute(
          method: :get,
          url: url,
          headers: headers,
          block_response: response_block
        )

        response_for_log = {
          code: response.code,
          headers: response.header,
          body: String.new,
          truncated: false
        }

        # NDJSON does not specify that empty lines are NOT allowed.
        # So just skip if last line is empty.
        unless next_block.nil? || next_block.strip.empty?
          recent_lines << next_block if line_count < MAX_RECENT_LINE_SIZE
          line_count += 1
          response_for_log[:body] = recent_lines.join

          log_and_reraise_if_error(request_for_log, response_for_log, line_count > MAX_RECENT_LINE_SIZE) do
            yield(response, next_block)
          end
        end

        if line_count > MAX_RECENT_LINE_SIZE
          response_for_log[:body] = "NOTE: RESPONSE TRUNCATED\nINFERNO ONLY DISPLAYS FIRST #{MAX_RECENT_LINE_SIZE} LINES\n\n#{response_for_log[:body]}"
        end
        LoggedRestClient.record_response(request_for_log, response_for_log)

        line_count
      end

      def get_file(file, use_token: true)
        headers = { accept: 'application/fhir+ndjson' }
        headers['Authorization'] = 'Bearer ' + @instance.bulk_access_token if use_token && @requires_access_token && @instance.bulk_access_token.present?

        url = file['url']
        LoggedRestClient.get(url, headers)
      end

      test :manifest_url_form do
        metadata do
          id '01'
          name 'Manifest is valid URL ending in $bulk-publish.'
          link SPEC_URL
          description %(
            TODO: write
          )
          versions :r4
        end

        @instance.url.chomp!('$bulk-publish')

        @instance.manifest_url = @instance.url.chomp('/') + '/$bulk-publish' if @instance.manifest_url.empty?

        assert @instance.manifest_url.ends_with?('$bulk-publish'), 'Manifest file must end in $bulk-publish'
        assert_valid_http_uri @instance.manifest_url

        pass "Will attempt to access manifest at #{@instance.manifest_url}"
      end

      test :manifest_downloadable do
        metadata do
          id '02'
          name 'Manifest file can be downloaded and is valid JSON.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        assert_valid_http_uri @instance.manifest_url
        headers = {}
        if @instance.custom_header&.include?(':')
          headers[@instance.custom_header.split(':').first.strip] = @instance.custom_header.split(':')[1].strip
          warning do
            assert false, 'Custom headers should not be required because their usage requires precoordination.'
          end
        end
        manifest_response = LoggedRestClient.get(@instance.manifest_url, headers)

        assert_response_ok(manifest_response)
        assert_valid_json(manifest_response.body)

        @manifest = JSON.parse(manifest_response.body)
      end

      test :manifest_minimum_requirement do
        metadata do
          id '03'
          name 'Manifest is structured properly and contains required keys.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded'

        # first pull out all the output files optimistically, so we can run other tests if these fail

        output = @manifest['output'] || []

        output.select { |line| line['type'] == 'Location' }.map { |line| line['url'] }

        @location_urls = output.select { |line| line['type'] == 'Location' && line.key?('url') }.map { |line| line['url'] }
        @schedule_urls = output.select { |line| line['type'] == 'Schedule' && line.key?('url') }.map { |line| line['url'] }
        @slot_urls = output.select { |line| line['type'] == 'Slot' && line.key?('url') }.map { |line| line['url'] }

        missing_fields = ['transactionTime', 'request', 'output'].reject { |field| @manifest.key? field }

        assert missing_fields.empty?, "Missing required field in manifest file: #{missing_fields.join(', ')}"

        valid_types = ['Location', 'Schedule', 'Slot']
        output.each do |file|
          assert file.key?('type'), 'Output file did not include type key'
          assert valid_types.include?(file['type']), "Type #{file['type']} is not one of the valid types for this use case: #{valid_types.join(',')}"
          assert file.key?('url'), 'Output file did not include url key'
          assert_valid_http_uri file['url']
        end

        pass "Manifest contains #{@location_urls.length} Location resource URL(s), #{@schedule_urls.length} Schedule resource URL(s), and #{@slot_urls.length} Slot resource URL(s)."
      end

      test :manifest_contains_jurisdictions do
        metadata do
          id '04'
          name 'State-level jurisdiction information is valid if included.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded'
        output = @manifest['output'] || []

        with_jurisdiction = output.select { |file| file.dig('extension', 'state').present? }

        states = Set.new

        with_jurisdiction.map { |file| file['extension']['state'] }.each do |state_list|
          assert state_list.is_a?(Array), 'States provided in extension must be an Array.'
          assert state_list.all? { |state| state.length == 2 }, 'All states must be 2-letter abbreviations.'
          states.merge(state_list.map(&:upcase))
        end

        omit 'No state-level jurisdiction information included.' if states.empty?

        pass "Jurisdiction information included #{states.length} unique state(s)."
      end

      test :manifest_since do
        metadata do
          id '05'
          name 'Request with since parameter filters data.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        omit 'Manifest since parameter not provided' if @instance.manifest_since.blank?
        skip_if @manifest.nil?, 'Manifest could not be loaded'
        begin
          date_is_iso8601 = true
          Date.iso8601(@instance.manifest_since)
        rescue RuntimeError, ArgumentError
          date_is_iso8601 = false
        end

        manifest_since_url = "#{@instance.manifest_url}?_since=#{CGI.escape(@instance.manifest_since)}"

        headers = { accept: 'application/fhir+ndjson' }
        headers[@instance.custom_header.split(':').first.strip] = @instance.custom_header.split(':')[1].strip if @instance.custom_header&.include?(':')

        manifest_response = LoggedRestClient.get(manifest_since_url, headers)

        assert_response_ok(manifest_response)
        assert_valid_json(manifest_response.body)

        manifest_since = JSON.parse(manifest_response.body)

        output = @manifest['output'] || []
        output_since = manifest_since['output'] || []

        equal_count = output.map { |file| file['url'] }.sort == output_since.map { |file| file['url'] }.sort

        assert date_is_iso8601, "#{@instance.manifest_since} does not appear to be a valid ISO8601 timestamp"

        assert !equal_count, "Expected since parameter to have effect on output of manifest but it still has the same #{output_since.length} values"

        pass "Manifest contains a different #{output_since.length} files with the since parameter than the #{output.length} files in the original manifest."
      end

      test :location_valid do
        metadata do
          id '06'
          name 'Location ndjson files contain valid FHIR resources that have all required fields.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded'
        skip_if @location_urls.empty?, 'No Locations provided'

        @location_reference_ids = Set.new

        # required
        invalid_id = nil

        # optional
        @invalid_district_count = 0
        @invalid_description_count = 0
        @invalid_position_count = 0

        success_count = test_output_against_profile('Location', [], @manifest['output']) do |resource|
          @location_reference_ids << "Location/#{resource.id}"

          invalid_id = resource.id unless /^[A-Za-z0-9\-\.]{1,64}$/.match?(resource.id)

          # this needs to be impoved
          @invalid_district_count += 1 if resource.address.is_a?(Array) || resource.address&.district.nil?
          @invalid_position_count += 1 if resource.position.nil?
        end

        assert invalid_id.nil?, "Invalid characters present in id: '#{invalid_id}'.  Must meet Regex '[A-Za-z0-9\-\.]{1,64}'."

        pass "#{success_count} Location resource(s) provided."
      end

      test :location_optional_district do
        metadata do
          id '07'
          name 'Location resources contain optional district.'
          link SPEC_URL
          description %(
            This is explicitely called out as an optional field for Location, and yet there are plenty
            of other valid optional Location elements.  Does that mean we should explicitely check for it?
          )
          versions :r4
          optional
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded'
        skip_if @location_urls.empty?, 'No Locations URLs provided.'
        skip_if @location_reference_ids.empty?, 'No Locations resources provided.'

        assert @invalid_district_count.zero?, "Found #{@invalid_district_count} missing or invalid address districts"
      end

      test :location_optional_description do
        metadata do
          id '08'
          name 'Location resources contain optional description'
          link SPEC_URL
          description %(
            This is explicitely called out as an optional field for Location, and yet there are plenty
            of other valid optional Location elements.  Does that mean we should explicitely check for it?
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded.'
        skip_if @location_urls.empty?, 'No Locations URLs provided.'
        skip_if @location_reference_ids.empty?, 'No Locations resources provided.'

        assert @invalid_description_count.zero?, "Found #{@invalid_description_count} missing or invalid descriptions"
      end

      test :location_optional_position do
        metadata do
          id '09'
          name 'Location resources contain optional position'
          link SPEC_URL
          description %(
            This is explicitely called out as an optional field for Location, and yet there are plenty
            of other valid optional Location elements.  Does that mean we should explicitely check for it?
          )
          versions :r4
          optional
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded.'
        skip_if @location_urls.empty?, 'No Locations URLs provided.'
        skip_if @location_reference_ids.empty?, 'No Locations resources provided.'

        assert @invalid_position_count.zero?, "Found #{@invalid_position_count} missing or invalid positions"
      end

      test :schedule_valid do
        metadata do
          id '10'
          name 'Schedule ndjson files contain valid FHIR resources that have all required fields'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded'
        skip_if @schedule_urls.empty?, 'No Schedules provided'

        @schedule_reference_ids = Set.new

        # required
        @unknown_location_reference = nil
        @unknown_location_reference_count = 0
        invalid_id = nil

        # optional
        @invalid_vaccine_product_count = 0
        @invalid_vaccine_dose_number_count = 0

        success_count = test_output_against_profile('Schedule', [], @manifest['output']) do |resource|
          @schedule_reference_ids << "Schedule/#{resource.id}"

          invalid_id = resource.id unless /^[A-Za-z0-9\-\.]{1,64}$/.match?(resource.id)

          resource&.actor&.each do |actor|
            reference = actor&.reference
            unless reference.nil?
              unless @location_reference_ids.include? reference
                @unknown_location_reference = reference
                @unknown_location_reference_count += 1
              end
            end
          end
        end

        assert invalid_id.nil?, "Invalid characters present in id: '#{invalid_id}'.  Must meet Regex '[A-Za-z0-9\-\.]{1,64}'."
        pass "#{success_count} Schedule resource(s) provided."
      end

      test :schedule_valid_reference_fields do
        metadata do
          id '11'
          name 'Schedule resources have valid reference fields.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded.'
        skip_if @schedule_urls.empty?, 'No Schedule URLs provided.'
        skip_if @schedule_reference_ids.empty?, 'No Schedule resources provided.'

        assert @unknown_location_reference.nil?, "#{@unknown_location_reference_count} unknown Locations referenced as actor (e.g. #{@unknown_location_reference})"
      end

      test :slot_valid do
        metadata do
          id '12'
          name 'Slot ndjson files contain valid FHIR resources that have all required fields.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded'
        skip_if @slot_urls.empty?, 'No slots provided'

        @slot_reference_ids = Set.new

        # required
        @unknown_schedule_reference_count = 0
        @unknown_schedule_reference = nil
        invalid_id = nil

        success_count = test_output_against_profile('Slot', [], @manifest['output']) do |resource|
          @slot_reference_ids << "Slot/#{resource.id}"
          schedule_reference = resource&.schedule&.reference
          invalid_id = resource.id unless /^[A-Za-z0-9\-\.]{1,64}$/.match?(resource.id)

          unless schedule_reference.nil?
            unless @schedule_reference_ids.include? schedule_reference
              @unknown_schedule_reference = schedule_reference
              @unknown_schedule_reference_count += 1
            end
          end
        end

        assert invalid_id.nil?, "Invalid characters present in id: '#{invalid_id}'.  Must meet Regex '[A-Za-z0-9\-\.]{1,64}'."
        pass "#{success_count} Slot resource(s) provided."
      end

      test :slot_valid_reference_fields do
        metadata do
          id '13'
          name 'Slot contains valid references.'
          link SPEC_URL
          description %(
            todo
          )
          versions :r4
        end

        skip_if @manifest.nil?, 'Manifest could not be loaded.'
        skip_if @slot_urls.empty?, 'No Slot URLs provided.'
        skip_if @slot_reference_ids.empty?, 'No Slot resources provided.'

        assert @unknown_schedule_reference.nil?, "#{@unknown_schedule_reference_count} unknown Schedules referenced (e.g. #{@unknown_schedule_reference})"
      end
    end
  end
end
