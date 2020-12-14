# frozen_string_literal: true

module Inferno
  module Sequence
    class McodeEverythingSequence < SequenceBase

      attr_accessor :additional_headers
      include SearchValidationUtil

      title 'mCODE Everything'

      description 'Verify support for the server capabilities required by the mCODE spec to retrieve all mCODE resources associated with a Cancer Patient using /$mcode-everything.'

      details %(
      )

      test_id_prefix 'MCODEEVERYTHING'
      requires :patient_ids
      conformance_supports :Patient

      @resource_found = nil

      test 'Patient supports $mcode-everything operation' do
        metadata do
          id '00'
          description %(
            Additional Patient resource requirement
          )
          versions :r4
        end
        # @client is from the FHIR client dependency go to crucibl on github and check the client library fhir
        # everything_response = @client.fetch_patient_record(@instance.patient_ids)
        everything_response = fetch_patient_mcode_record(@instance.patient_ids)
        skip_unless [200, 201].include?(everything_response.code)
        @everything = everything_response.resource
        assert !@everything.nil?, 'Expected valid non-nil Bundle resource on $mcode-everything request'
        assert @everything.is_a?(versioned_resource_class('Bundle')), 'Expected resource to be valid Bundle'
        # assert @everything.meta.profile = 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-patient-bundle'
        # profile = {url = 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-patient-bundle'}
        # profile.validate_resource(everything_response.resource);
        # profile.url = 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-patient-bundle'
        # validate_resource('Bundle', @everything, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-patient-bundle')
        # validate_mcode_resource('Bundle', @everything)

        # First entry must be a cancer patient.
        # assert @everything.entry[0]
        # @everything.entry do |entry|

      end


      def validate_mcode_resource(resource_type, resource)
        resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-patient-bundle')

        errors = resource_validation_errors[:errors]
        errors.concat(yield resource) if block_given?

        @test_warnings.concat resource_validation_errors[:warnings]
        @information_messages.concat resource_validation_errors[:information]

        errors.map! { |e| "#{resource_type}/#{resource.id}: #{e}" }
        @profiles_failed['http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-patient-bundle'].concat(errors) unless errors.empty?
        errors
      end

      def fetch_patient_mcode_record(id = nil, startTime = nil, endTime = nil, method = 'GET', format = nil)
        fetch_record(id, [startTime, endTime], method, versioned_resource_class('Patient'), format)
      end

      def versioned_resource_class(klass = nil)
        mod = case @fhir_version
              when :stu3
                FHIR::STU3
              when :dstu2
                FHIR::DSTU2
              else
                FHIR
              end
        return mod if klass.nil?
        mod.const_get(klass)
      end

      def fetch_record(id = nil, time = [nil, nil], method = 'GET', klass = versioned_resource_class('Patient'), format = nil)
        @default_format = versioned_format_class(:json)
        headers = {}
        headers[:accept] =  "#{format}" if format
        format ||= @default_format
        headers[:content_type] = format
        options = { resource: klass, format: format, operation: { name: :fetch_patient_mcode_record, method: method } }
        options.deep_merge!(id: id) unless id.nil?
        options[:operation][:parameters] = {} if options[:operation][:parameters].nil?
        options[:operation][:parameters][:start] = { type: 'Date', value: time.first } unless time.first.nil?
        options[:operation][:parameters][:end] = { type: 'Date', value: time.last } unless time.last.nil?

        if options[:operation][:method] == 'GET'
          reply = @client.get resource_url(options), @client.fhir_headers
        else
          # create Parameters body
          if options[:operation] && options[:operation][:parameters]
            p = versioned_resource_class('Parameters').new
            options[:operation][:parameters].each do |key, value|
              parameter = versioned_resource_class('Parameters::Parameter').new.from_hash(name: key.to_s)
              parameter.method("value#{value[:type]}=").call(value[:value])
              p.parameter << parameter
            end
          end
          reply = post resource_url(options), p, @client.fhir_headers(headers)
        end

        reply.resource = @client.parse_reply(versioned_resource_class('Bundle'), format, reply)
        reply.resource_class = options[:resource]
        reply
      end

      DEFAULTS = {
        id: nil,
        resource: nil,
        format: 'application/fhir+xml'
      }.freeze

      def versioned_format_class(format = nil)
      if @fhir_version == :dstu2
        case format
        when nil
          @default_format.include?('xml') ?
              FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2 :
              FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
        when :xml
          FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2
        else
          FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
        end
      else
        case format
        when nil
          @default_format.include?('xml') ?
              FHIR::Formats::ResourceFormat::RESOURCE_XML :
              FHIR::Formats::ResourceFormat::RESOURCE_JSON
        when :xml
          FHIR::Formats::ResourceFormat::RESOURCE_XML
        else
          FHIR::Formats::ResourceFormat::RESOURCE_JSON
        end
      end
    end

      def resource_url(options, use_format_param = false)
        options = DEFAULTS.merge(options)
  
        params = {}
        url = ''
        # handle requests for resources by class or string; useful for testing nonexistent resource types
        url += "/#{options[:resource].try(:name).try(:demodulize) || options[:resource].split('::').last}" if options[:resource]
        url += "/#{options[:id]}" if options[:id]
        url += '/$validate' if options[:validate]
        url += '/$match' if options[:match]
  
        if options[:operation]
          opr = options[:operation]
          p = opr[:parameters]
          p = p.each { |k, v| p[k] = v[:value] } if p
          params.merge!(p) if p && opr[:method] == 'GET'
  
          if opr[:name] == :fetch_patient_mcode_record
            url += '/$mcode-everything'
          elsif opr[:name] == :value_set_expansion
            url += '/$expand'
          elsif opr  && opr[:name] == :value_set_based_validation
            url += '/$validate-code'
          elsif opr  && opr[:name] == :code_system_lookup
            url += '/$lookup'
          elsif opr  && opr[:name] == :concept_map_translate
            url += '/$translate'
          elsif opr  && opr[:name] == :closure_table_maintenance
            url += '/$closure'
          end
        end
  
        if options[:history]
          history = options[:history]
          url += '/_history'
          url += "/#{history[:id]}" if history.key?(:id)
          params[:_count] = history[:count] if history[:count]
          params[:_since] = history[:since].iso8601 if history[:since]
        end
  
        if options[:search]
          search_options = options[:search]
          url += '/_search' if search_options[:flag]
          url += "/#{search_options[:compartment]}" if search_options[:compartment]
  
          if search_options[:parameters]
            search_options[:parameters].each do |key, value|
              params[key.to_sym] = value
            end
          end
        end
  
        # options[:params] is simply appended at the end of a url and is used by testscripts
        url += options[:params] if options[:params]
  
        params[:_summary] = options[:summary] if options[:summary]
  
        if use_format_param && options[:format]
          params[:_format] = options[:format]
        end
  
        uri = Addressable::URI.parse(url)
        # params passed in options takes precidence over params calculated in this method
        # for use by testscript primarily
        uri.query_values = params unless options[:params] && options[:params].include?('?')
        uri.normalize.to_str
      end

      # def fhir_headers(options = {})
      #   FHIR::ResourceAddress.fhir_headers(options, additional_headers, @default_format, @use_accept_header, @use_accept_charset)
      # end
      
    end
  end
end