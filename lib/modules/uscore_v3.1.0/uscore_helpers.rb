module Inferno
  module USCoreHelpers
    def save_delayed_sequence_references(resources, delayed_sequence_references)
      resources.each do |resource|
        walk_resource(resource) do |value, meta, path|
          next if meta['type'] != 'Reference'

          if value.relative?
            begin
              resource_class = value.resource_class.name.demodulize
              delayed_sequence_reference = delayed_sequence_references.find { |ref| ref[:path] == path }
              is_delayed = delayed_sequence_reference.present? && delayed_sequence_reference[:resources].include?(resource_class)
              @instance.save_resource_reference_without_reloading(resource_class, value.reference.split('/').last) if is_delayed
            rescue NameError
              next
            end
          end
        end
      end

      @instance.reload
    end

    def resolve_path(elements, path)
      elements = Array.wrap(elements)
      return elements if path.blank?

      paths = path.split('.')

      elements.flat_map do |element|
        resolve_path(element&.send(paths.first), paths.drop(1).join('.'))
      end.compact
    end

    def resolve_element_from_path(element, path)
      el_as_array = Array.wrap(element)
      if path.empty?
        return nil if element.nil?

        return el_as_array.find { |el| yield(el) } if block_given?

        return el_as_array.first
      end

      path_ary = path.split('.')
      cur_path_part = path_ary.shift.to_sym
      return nil if el_as_array.none? { |el| el.send(cur_path_part).present? }

      el_as_array.each do |el|
        el_found = if block_given?
                     resolve_element_from_path(el.send(cur_path_part), path_ary.join('.')) { |value_found| yield(value_found) }
                   else
                     resolve_element_from_path(el.send(cur_path_part), path_ary.join('.'))
                   end
        return el_found unless el_found.blank?
      end

      nil
    end

    def get_value_for_search_param(element, include_system = false)
      search_value = case element
                     when FHIR::Period
                       if element.start.present?
                         'gt' + element.start
                       else
                         'lt' + element.end
                       end
                     when FHIR::Reference
                       element.reference
                     when FHIR::CodeableConcept
                       if include_system
                         coding_with_code = resolve_element_from_path(element, 'coding') { |coding| coding.code.present? }
                         coding_with_code.present? ? "#{coding_with_code.system}|#{coding_with_code.code}" : nil
                       else
                         resolve_element_from_path(element, 'coding.code')
                       end
                     when FHIR::Identifier
                       if include_system
                         "#{element.system}|#{element.value}"
                       else
                         element.value
                       end
                     when FHIR::Coding
                       if include_system
                         "#{element.system}|#{element.code}"
                       else
                         element.code
                       end
                     when FHIR::HumanName
                       element.family || element.given&.first || element.text
                     when FHIR::Address
                       element.text || element.city || element.state || element.postalCode || element.country
                     else
                       element
                     end
      escaped_value = search_value&.gsub(',', '\\,')
      escaped_value
    end

    def date_comparator_value(comparator, date)
      date = date.slice(2..-1) if ['gt', 'ge', 'lt', 'le'].include? date[0, 2]

      case comparator
      when 'lt', 'le'
        comparator + (DateTime.xmlschema(date) + 1).xmlschema
      when 'gt', 'ge'
        comparator + (DateTime.xmlschema(date) - 1).xmlschema
      else
        ''
      end
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

    # pattern, values, type
    def find_slice(resource, path_to_ary, discriminator)
      resolve_element_from_path(resource, path_to_ary) do |array_el|
        case discriminator[:type]
        when 'patternCodeableConcept'
          path_to_coding = discriminator[:path].present? ? [discriminator[:path], 'coding'].join('.') : 'coding'
          resolve_element_from_path(array_el, path_to_coding) do |coding|
            coding.code == discriminator[:code] && coding.system == discriminator[:system]
          end
        when 'patternIdentifier'
          resolve_element_from_path(array_el, discriminator[:path]) { |identifier| identifier.system == discriminator[:system] }
        when 'value'
          values_clone = discriminator[:values].deep_dup
          values_clone.each do |value_def|
            value_def[:path] = value_def[:path].split('.')
          end
          find_slice_by_values(array_el, values_clone)
        when 'type'
          case discriminator[:code]
          when 'Date'
            begin
              Date.parse(array_el)
            rescue ArgumentError
              false
            end
          when 'String'
            array_el.is_a? String
          else
            array_el.is_a? FHIR.const_get(discriminator[:code])
          end
        end
      end
    end

    def find_slice_by_values(element, values)
      unique_first_part = values.map { |value_def| value_def[:path].first }.uniq
      Array.wrap(element).find do |el|
        unique_first_part.all? do |part|
          values_matching = values.select { |value_def| value_def[:path].first == part }
          values_matching.each { |value_def| value_def[:path] = value_def[:path].drop(1) }
          resolve_element_from_path(el, part) do |el_found|
            all_matches = values_matching.select { |value_def| value_def[:path].empty? }.all? { |value_def| value_def[:value] == el_found }
            remaining_values = values_matching.reject { |value_def| value_def[:path].empty? }
            remaining_matches = remaining_values.present? ? find_slice_by_values(el_found, remaining_values) : true
            all_matches && remaining_matches
          end
        end
      end
    end

    def resources_with_invalid_binding(binding_def, resources)
      path_source = resources
      resources.map do |resource|
        binding_def[:extensions]&.each do |url|
          path_source = path_source.map { |el| el.extension.select { |extension| extension.url == url } }.flatten
        end
        invalid_code_found = resolve_element_from_path(path_source, binding_def[:path]) do |el|
          case binding_def[:type]
          when 'CodeableConcept'
            if el.is_a? FHIR::CodeableConcept
              # If we're validating a valueset (AKA if we have a 'system' URL)
              # We want at least one of the codes to be in the valueset
              if binding_def[:system].present?
                el.coding.none? do |coding|
                  Terminology.validate_code(valueset_url: binding_def[:system],
                                            code: coding.code,
                                            system: coding.system)
                end
              # If we're validating a codesystem (AKA if there's no 'system' URL)
              # We want all of the codes to be in their respective systems
              else
                el.coding.any? do |coding|
                  Terminology.validate_code(valueset_url: nil,
                                            code: coding.code,
                                            system: coding.system)
                end
              end
            else
              false
            end
          when 'Quantity', 'Coding'
            !Terminology.validate_code(valueset_url: binding_def[:system],
                                       code: el.code,
                                       system: el.system)
          when 'code'
            !Terminology.validate_code(valueset_url: binding_def[:system], code: el)
          else
            false
          end
        end

        { resource: resource, element: invalid_code_found } if invalid_code_found.present?
      end.compact
    end

    def invalid_binding_message(invalid_binding, binding_def)
      code_as_string = invalid_binding[:element]
      if invalid_binding[:element].is_a? FHIR::CodeableConcept
        code_as_string = invalid_binding[:element]&.coding&.map do |coding|
          "#{coding.system}|#{coding.code}"
        end&.join(' or ')
      elsif invalid_binding[:element].is_a?(FHIR::Coding) || invalid_binding[:element].is_a?(FHIR::Quantity)
        code_as_string = "#{invalid_binding[:element].system}|#{invalid_binding[:element].code}"
      end
      binding_entity = binding_def[:system].presence || 'the declared CodeSystem'

      "#{invalid_binding[:resource].resourceType}/#{invalid_binding[:resource].id} " \
      "at #{invalid_binding[:resource].resourceType}.#{binding_def[:path]} with code '#{code_as_string}' " \
      "is not in #{binding_entity}"
    end
  end
end
