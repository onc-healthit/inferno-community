# frozen_string_literal: true

require_relative '../test_metadata'

module Inferno
  module Generator
    module MustSupportTest
      def create_mustsupport_tests(metadata)
        must_support_list = metadata.must_supports[:elements].map { |element| "* #{element[:path]}" } +
                            metadata.must_supports[:extensions].map { |extension| "* #{extension[:id]}" } +
                            metadata.must_supports[:slices].map { |slice| "* #{slice[:name]}" }

        must_support_test = TestMetadata.new(
          title: "All must support elements are provided in the #{metadata.resource_type} resources returned.",
          key: :must_support,
          description: %(
            This will look through the #{metadata.resource_type} resource for the following must support elements:

            #{must_support_list.sort.join("\n            ")}
          ),
          optional: true
        )

        must_support_extensions = metadata.must_supports[:extensions]
        must_support_slices = metadata.must_supports[:slices]
        must_support_elements = metadata.must_supports[:elements]

        must_support_elements.each { |must_support| must_support[:path]&.gsub!('[x]', '')&.gsub!(/(?<!\w)class(?!\w)/, 'local_class') }
        must_support_slices.each { |must_support| must_support[:path]&.gsub!('[x]', '')&.gsub!(/(?<!\w)class(?!\w)/, 'local_class') }

        must_support_test.code = %(
          skip 'No resource found from Read test' unless @resource_found.present?
          must_supports = #{metadata.class_name}Definitions::MUST_SUPPORTS
        )
        if must_support_extensions.present?
          must_support_test.code += %(
            missing_must_support_extensions = must_supports[:extensions].reject do |must_support_extension|
              @resource_found.extension.any? { |extension| extension.url == must_support_extension[:url] }
            end
          )
        end

        if must_support_slices.present?
          must_support_test.code += %(
            missing_slices = must_supports[:slices]
              .select { |slice| slice[:discriminator].present? }
              .reject do |slice|
                slice_found = find_slice(@resource_found, slice[:path], slice[:discriminator])
                slice_found.present?
              end
          )
        end

        if must_support_elements.present?
          must_support_test.code += %(
            missing_must_support_elements = must_supports[:elements].reject do |element|
              value_found = resolve_element_from_path(@resource_found, element[:path]) do |value|
                value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
                (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
              end

              # Note that false.present? => false, which is why we need to add this extra check
              value_found.present? || value_found == false
            end
            missing_must_support_elements.map! { |must_support| "\#{must_support[:path]}\#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }
          )
        end

        if must_support_extensions.present?
          must_support_test.code += %(
            missing_must_support_elements += missing_must_support_extensions.map { |must_support| must_support[:id] }
          )
        end
        if must_support_slices.present?
          must_support_test.code += %(
            missing_must_support_elements += missing_slices.map { |slice| slice[:name] }
          )
        end

        must_support_test.code += %(
          skip_if missing_must_support_elements.present?,
            "Could not find \#{missing_must_support_elements.join(', ')} in the provided resource"
          @instance.save!
        )

        metadata.add_test(must_support_test)
      end
    end
  end
end
