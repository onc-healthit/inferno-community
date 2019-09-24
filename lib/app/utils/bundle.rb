# frozen_string_literal: true

module Inferno
  module BundleParserUtil
    def get_resource_by_id(bundle, resource_id)
      bundle.entry.select { |e| e.resource.id == resource_id }.first.resource
    end

    def get_related_library_ids(measure)
      measure.library.map { |lib| lib.reference.sub 'Library/', '' }
    end

    def get_valueset_urls(library)
      value_set_strings = library.dataRequirement.map { |dr| dr.codeFilter[0].valueSetString }
      value_set_strings = value_set_strings.compact.uniq
      # Grab only the oid part of each valueSetString
      value_set_strings.map { |s| s[/([0-9]+\.)+[0-9]+/] }
    end

    def get_all_dependent_valuesets(measure, bundle)
      all_dependent_valuesets = []
      processed = Set.new
      # The entry measure has related libraries but no data requirements, so do
      # one pass before entering the loop
      to_process = get_related_library_ids(measure)
      processed << measure.id

      to_process.each do |library_id|
        next if processed.include? library_id

        processed << library_id

        library = get_resource_by_id(bundle, library_id)
        get_valueset_urls(library).each { |url| all_dependent_valuesets << url }
      end

      all_dependent_valuesets.uniq
    end
  end
end
