# Extend StructureDefinition for profile validation code
require 'nokogiri'
require 'yaml'
require 'bcp47'

module FHIR
  module DSTU2
    class StructureDefinition
      extend FHIR::DSTU2::Deprecate
      attr_accessor :finding
      attr_accessor :errors
      attr_accessor :warnings
      attr_accessor :hierarchy

      # -------------------------------------------------------------------------
      #                            Profile Validation
      # -------------------------------------------------------------------------

      @@vs_validators = Hash.new
      def self.register_vs_validator(valueset_uri, validator_fn)
        @@vs_validators[valueset_uri] = validator_fn
      end

      def validates_resource?(resource)
        validate_resource(resource).empty?
      end

      def validate_resource(resource)
        @errors = []
        @warnings = []
        if resource.is_a?(FHIR::DSTU2::Model)
          valid_json?(resource.to_json) if resource
        else
          @errors << "#{resource.class} is not a resource."
        end
        # TODO: return warnings too!
        @errors
      end

      def validates_hash?(hash)
        @errors = []
        @warnings = []
        valid_json?(hash) if hash
        @errors
      end

      # Checks whether or not the "json" is valid according to this definition.
      # json == the raw json for a FHIR::DSTU2 resource
      def valid_json?(json)
        build_hierarchy if @hierarchy.nil?

        if json.is_a? String
          begin
            json = JSON.parse(json)
          rescue => e
            @errors << "Failed to parse JSON: #{e.message} %n #{h} %n #{e.backtrace.join("\n")}"
            return false
          end
        end

        @hierarchy.children.each do |element|
          verify_element(element, json)
        end

        @errors.size.zero?
      end
      deprecate :is_valid_json?, :valid_json?

      def build_hierarchy
        @hierarchy = nil
        snapshot.element.each do |element|
          if @hierarchy.nil?
            @hierarchy = element
          else
            @hierarchy.add_descendent(element)
          end
        end
        if differential
          changelist = differential.element.map(&:path)
          @hierarchy.keep_children(changelist)
          @hierarchy.sweep_children
        end
        @hierarchy
      end

      def describe_element(element)
        if element.path.end_with?('.extension', '.modifierExtension') && element.name
          "#{element.path} (#{element.name})"
        else
          element.path
        end
      end

      def get_json_nodes(json, path)
        results = []
        return [json] if path.nil?
        steps = path.split('.')
        steps.each.with_index do |step, index|
          if json.is_a? Hash
            json = json[step]
          elsif json.is_a? Array
            json.each do |e|
              results << get_json_nodes(e, steps[index..-1].join('.'))
            end
            return results.flatten!
          else
            # this thing doesn't exist
            return results
          end
          return results if json.nil?
        end

        if json.is_a? Array
          results += json
        else
          results << json
        end
        results
      end

      def verify_element(element, json)
        path = element.local_name || element.path
        path = path[(@hierarchy.path.size + 1)..-1] if path.start_with? @hierarchy.path

        begin
          data_type_found = element.type.first.code
        rescue
          data_type_found = nil
        end

        # get the JSON nodes associated with this element path
        if path.end_with?('[x]')
          nodes = []
          element.type.each do |type|
            data_type_found = type.code
            capcode = type.code.clone
            capcode[0] = capcode[0].upcase
            nodes = get_json_nodes(json, path.gsub('[x]', capcode))
            break unless nodes.empty?
          end
        else
          nodes = get_json_nodes(json, path)
        end

        # special filtering on extension urls
        extension_profile = element.type.find { |t| t.code == 'Extension' && !t.profile.nil? }
        if extension_profile
          nodes = nodes.select { |x| extension_profile.profile.first == x['url'] }
        end

        # Check the cardinality
        min = element.min
        max = element.max == '*' ? Float::INFINITY : element.max.to_i
        if (nodes.size < min) || (nodes.size > max)
          @errors << "#{describe_element(element)} failed cardinality test (#{min}..#{max}) -- found #{nodes.size}"
        end

        return if nodes.empty?
        # Check the datatype for each node, only if the element has one declared, and it isn't the root element
        if !element.type.empty? && element.path != id
          codeable_concept_pattern = element.pattern && element.pattern.is_a?(FHIR::DSTU2::CodeableConcept)
          codeable_concept_binding = element.binding
          matching_pattern = false
          nodes.each do |value|
            matching_type = 0

            # the element is valid, if it matches at least one of the datatypes
            temp_messages = []
            verified_extension = false
            verified_data_type = false
            if data_type_found == 'Extension' # && !type.profile.nil?
              verified_extension = true
              # TODO: should verify extensions
              # extension_def = FHIR::DSTU2::Definitions.get_extension_definition(value['url'])
              # if extension_def
              #   verified_extension = extension_def.validates_resource?(FHIR::DSTU2::Extension.new(deep_copy(value)))
              # end
            elsif data_type_found
              temp = @errors
              @errors = []
              verified_data_type = data_type?(data_type_found, value)
              temp_messages << @errors
              @errors = temp
            end
            if data_type_found && (verified_extension || verified_data_type)
              matching_type += 1
              if data_type_found == 'code' # then check the binding
                unless element.binding.nil?
                  matching_type += check_binding_element(element, value)
                end
              elsif data_type_found == 'CodeableConcept' && codeable_concept_pattern
                vcc = FHIR::DSTU2::CodeableConcept.new(value)
                pattern = element.pattern.coding
                pattern.each do |pcoding|
                  vcc.coding.each do |vcoding|
                    matching_pattern = true if vcoding.system == pcoding.system && vcoding.code == pcoding.code
                  end
                end
              elsif data_type_found == 'CodeableConcept' && codeable_concept_binding
                binding_issues = if element.binding.strength == "extensible"
                  @errors # TODO make this @warnings, once we have a way to return warnings
                elsif element.binding.strength == "required"
                  @errors
                else # e.g., example-strength or unspecified
                  [ ] # Drop issues errors on the floor, in throwaway array
                end

                valueset_uri = element.binding.try(:valueSetReference).try(:reference)
                if @@vs_validators and @@vs_validators[valueset_uri]
                  check_fn = @@vs_validators[valueset_uri]
                  vcc = FHIR::DSTU2::CodeableConcept.new(value)

                  has_valid_code = vcc.try(:coding).any? {|c| check_fn.call(c)}
                  unless has_valid_code
                    binding_issues << "#{describe_element(element)} has no codings from #{valueset_uri}. Codings evaluated: #{value.to_json}"
                  end
                end
              elsif data_type_found == 'String' && !element.maxLength.nil? && (value.size > element.maxLength)
                @errors << "#{describe_element(element)} exceed maximum length of #{element.maxLength}: #{value}"
              end
            elsif data_type_found
              temp_messages << "#{describe_element(element)} is not a valid #{data_type_found}: '#{value}'"
            else
              # we don't know the data type... so we say "OK"
              matching_type += 1
              @warnings >> "Unable to guess data type for #{describe_element(element)}"
            end

            if matching_type <= 0
              @errors += temp_messages
              @errors << "#{describe_element(element)} did not match one of the valid data types: #{element.type.map(&:code)}"
            else
              @warnings += temp_messages
            end
            if !element.fixed.nil? && element.fixed != value
              @errors << "#{describe_element(element)} value of '#{value}' did not match fixed value: #{element.fixed}"
            end
          end
          if codeable_concept_pattern && matching_pattern == false
            @errors << "#{describe_element(element)} CodeableConcept did not match defined pattern: #{element.pattern.to_hash}"
          end
        end

        # In STU3 we check element.constraint.expression using FluentPath.
        # In DSTU2, constraints were given by element.constraint.xpath.
        # We do *NOT* check these XPath constraints.

        # check children if the element has any
        return unless element.children
        nodes.each do |node|
          element.children.each do |child|
            verify_element(child, node)
          end
        end
      end

      # data_type_code == a FHIR::DSTU2 DataType code (see http://hl7.org/fhir/2015May/datatypes.html)
      # value == the representation of the value
      def data_type?(data_type_code, value)
        # FHIR::DSTU2 models covers any base Resources
        if FHIR::DSTU2::RESOURCES.include?(data_type_code)
          definition = FHIR::DSTU2::Definitions.resource_definition(data_type_code)
          unless definition.nil?
            ret_val = false
            begin
              # klass = Module.const_get("FHIR::DSTU2::#{data_type_code}")
              # ret_val = definition.validates_resource?(klass.new(deep_copy(value)))
              ret_val = definition.validates_hash?(value)
              unless ret_val
                @errors += definition.errors
                @warnings += definition.warnings
              end
            rescue
              @errors << "Unable to verify #{data_type_code} as a FHIR::DSTU2 Resource."
            end
            return ret_val
          end
        end

        # Remaining data types: handle special cases before checking type StructureDefinitions
        case data_type_code.downcase
        when 'domainresource'
          true # we don't have to verify domain resource, because it will be included in the snapshot
        when 'resource'
          resource_type = value['resourceType']
          definition = FHIR::DSTU2::Definitions.resource_definition(resource_type)
          if !definition.nil?
            ret_val = false
            begin
              # klass = Module.const_get("FHIR::DSTU2::#{resource_type}")
              # ret_val = definition.validates_resource?(klass.new(deep_copy(value)))
              ret_val = definition.validates_hash?(value)
              unless ret_val
                @errors += definition.errors
                @warnings += definition.warnings
              end
            rescue
              @errors << "Unable to verify #{resource_type} as a FHIR::DSTU2 Resource."
            end
            ret_val
          else
            @errors << "Unable to find base Resource definition: #{resource_type}"
            false
          end
        when *FHIR::DSTU2::PRIMITIVES.keys.map(&:downcase)
          FHIR::DSTU2.primitive?(datatype: data_type_code, value: value)
        else
          # Eliminate endless loop on Element is an Element
          return true if data_type_code == 'Element' && id == 'Element'

          definition = FHIR::DSTU2::Definitions.type_definition(data_type_code)
          definition = FHIR::DSTU2::Definitions.resource_definition(data_type_code) if definition.nil?
          if !definition.nil?
            ret_val = false
            begin
              # klass = Module.const_get("FHIR::DSTU2::#{data_type_code}")
              # ret_val = definition.validates_resource?(klass.new(deep_copy(value)))
              ret_val = definition.validates_hash?(value)
              unless ret_val
                @errors += definition.errors
                @warnings += definition.warnings
              end
            rescue
              @errors << "Unable to verify #{data_type_code} as a FHIR::DSTU2 type."
            end
            ret_val
          else
            @errors << "Unable to find base type definition: #{data_type_code}"
            false
          end
        end
      end
      deprecate :is_data_type?, :data_type?

      def check_binding_element(element, value)
        vs_uri = element.binding.valueSetUri || element.binding.valueSetReference.reference
        valueset = FHIR::DSTU2::Definitions.get_codes(vs_uri)

        matching_type = 0

        if %w[http://hl7.org/fhir/ValueSet/content-type http://www.rfc-editor.org/bcp/bcp13.txt].include?(vs_uri)
          matches = MIME::Types[value]
          if (matches.nil? || matches.size.zero?) && !some_type_of_xml_or_json?(value)
            @errors << "#{element.path} has invalid mime-type: '#{value}'"
            matching_type -= 1 if element.binding.strength == 'required'
          end
        elsif %w[http://hl7.org/fhir/ValueSet/languages http://tools.ietf.org/html/bcp47].include?(vs_uri)
          has_region = !(value =~ /-/).nil?
          valid = !BCP47::Language.identify(value.downcase).nil? && (!has_region || !BCP47::Region.identify(value.upcase).nil?)
          unless valid
            @errors << "#{element.path} has unrecognized language: '#{value}'"
            matching_type -= 1 if element.binding.strength == 'required'
          end
        elsif valueset.nil?
          @warnings << "#{element.path} has unknown ValueSet: '#{vs_uri}'"
          if element.binding.strength == 'required'
            if element.short
              @warnings << "#{element.path} guessing codes for ValueSet: '#{vs_uri}'"
              guess_codes = element.short.split(' | ')
              matching_type -= 1 unless guess_codes.include?(value)
            else
              matching_type -= 1
            end
          end
        elsif !valueset.values.flatten.include?(value)
          message = "#{element.path} has invalid code '#{value}' from #{valueset}"
          if element.binding.strength == 'required'
            @errors << message
            matching_type -= 1
          else
            @warnings << message
          end
        end

        matching_type
      end

      def some_type_of_xml_or_json?(code)
        m = code.downcase
        return true if %w[xml json].include?(m)
        return true if (m.starts_with?('application/') || m.starts_with?('text/')) && (m.ends_with?('json') || m.ends_with?('xml'))
        return true if m.starts_with?('application/xml') || m.starts_with?('text/xml')
        return true if m.starts_with?('application/json') || m.starts_with?('text/json')
        false
      end
      deprecate :is_some_type_of_xml_or_json, :some_type_of_xml_or_json?

      private :valid_json?, :get_json_nodes, :build_hierarchy, :verify_element, :check_binding_element
    end
  end
end
