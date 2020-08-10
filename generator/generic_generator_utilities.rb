# frozen_string_literal: true

module Inferno
  module Generator
    module GenericGeneratorUtilties
      EXPECTATION_URL = 'http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation'

      def structure_to_string(struct)
        if struct.is_a? Hash
          %({
            #{struct.map { |k, v| "#{k}: #{structure_to_string(v)}" }.join(",\n")}
          })
        elsif struct.is_a? Array
          if struct.empty?
            '[]'
          else
            %([
              #{struct.map { |el| structure_to_string(el) }.join(",\n")}
            ])
          end
        elsif struct.is_a? String
          "'#{struct}'"
        elsif [true, false].include? struct
          struct.to_s
        else
          "''"
        end
      end

      def create_search_validation(sequence_metadata)
        search_validators = ''
        sequence_metadata.search_parameter_metadata&.each do |parameter_metadata|
          type = sequence_metadata.element_type_by_path(parameter_metadata.expression) || parameter_metadata.type
          path = parameter_metadata.expression
            .gsub(/(?<!\w)class(?!\w)/, 'local_class')
            .split('.')
            .drop(1)
            .join('.')

          # handle some fhir path stuff. Remove this once fhir path server is added
          path = path.gsub(/.where\((.*)/, '')
          as_type = path.scan(/.as\((.*?)\)/).flatten.first
          path = path.gsub(/.as\((.*?)\)/, capitalize_first_letter(as_type)) if as_type.present?

          path += get_value_path_by_type(type) unless ['Period', 'date', 'HumanName', 'Address', 'CodeableConcept', 'Coding', 'Identifier'].include? type
          parameter_code = parameter_metadata.code
          resource_type = sequence_metadata.resource_type
          search_validators += %(
              when '#{parameter_metadata.code}'
              values_found = resolve_path(resource, '#{path}')
              #{search_param_match_found_code(type, parameter_metadata.code)}
              assert match_found, "#{parameter_code} in #{resource_type}/\#{resource.id} (\#{values_found}) does not match #{parameter_code} requested (\#{value})"
            )
        end

        validate_functions =
          if search_validators.empty?
            ''
          else
            %(
              def validate_resource_item(resource, property, value)
                case property
                  #{search_validators}
                end
              end
            )
          end
        validate_functions
      end

      def search_param_match_found_code(type, element)
        case type
        when 'Period', 'date'
          %(match_found = values_found.any? { |date| validate_date_search(value, date) })
        when 'HumanName'
          # When a string search parameter refers to the types HumanName and Address,
          # the search covers the elements of type string, and does not cover elements such as use and period
          # https://www.hl7.org/fhir/search.html#string
          %(value_downcase = value.downcase
            match_found = values_found.any? do |name|
              name&.text&.downcase&.start_with?(value_downcase) ||
                name&.family&.downcase&.include?(value_downcase) ||
                name&.given&.any? { |given| given.downcase.start_with?(value_downcase) } ||
                name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value_downcase) } ||
                name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value_downcase) }
            end)
        when 'Address'
          %(match_found = values_found.any? do |address|
              address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
            end)
        when 'CodeableConcept'
          %(coding_system = value.split('|').first.empty? ? nil : value.split('|').first
            coding_value = value.split('|').last
            match_found = values_found.any? do |codeable_concept|
              if value.include? '|'
                codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
              else
                codeable_concept.coding.any? { |coding| coding.code == value }
              end
            end)
        when 'Identifier'
          %(identifier_system = value.split('|').first.empty? ? nil : value.split('|').first
            identifier_value = value.split('|').last
            match_found = values_found.any? do |identifier|
              identifier.value == identifier_value && (!value.include?('|') || identifier.system == identifier_system)
            end)
        else
          # searching by patient requires special case because we are searching by a resource identifier
          # references can also be URL's, so we made need to resolve those url's
          if ['subject', 'patient'].include? element.to_s
            %(value = value.split('Patient/').last
              match_found = values_found.any? { |reference| [value, 'Patient/' + value, "\#{@instance.url}/Patient/\#{value}"].include? reference })
          else
            %(values = value.split(/(?<!\\\\),/).each { |str| str.gsub!('\\,', ',') }
              match_found = values_found.any? { |value_in_resource| values.include? value_in_resource })
          end
        end
      end

      def capitalize_first_letter(str)
        str.slice(0).capitalize + str.slice(1..-1)
      end

      def get_value_path_by_type(type)
        case type
        when 'CodeableConcept'
          '.coding.code'
        when 'Reference', 'reference'
          '.reference'
        when 'Period'
          '.start'
        when 'Identifier'
          '.value'
        when 'Coding'
          '.code'
        when 'HumanName'
          '.family'
        when 'Address'
          '.city'
        else
          ''
        end
      end
    end
  end
end
