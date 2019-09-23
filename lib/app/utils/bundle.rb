# frozen_string_literal: true

module Inferno
  module BundleParserUtil
    def get_resource_by_id(bundle, resouce_id)
      bundle.entry.select { |e| e.resource.id == resouce_id }.first.resource
    end

    def get_related_library_ids(measure)
      measure.library.map { |lib| lib.reference.sub 'Library/', '' }
    end

    def get_data_requirements(library)
      library['resource']['dataRequirement']
    end

    def get_valueset_urls(library)
      library.dataRequirement.map { |dr| dr.codeFilter[0].valueSetString.sub 'urn:oid:', '' }.uniq
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
