# frozen_string_literal: true

module Inferno
  module MeasureBundleParserUtil
    def get_library_by_id(measurebundle, library_id)
      measurebundle['entry'].filter { |m| m['resource']['id'] == library_id }.first
    end

    def get_related_libraries(library)
      library['resource']['library'].map { |lib| lib['reference'].sub 'Library/', '' }
    end

    def get_data_requirements(library)
      library['resource']['dataRequirement']
    end

    def get_valueset_urls(library)
      data_requirements = get_data_requirements(library)
      valueset_urls = data_requirements&.map { |vs| vs['codeFilter'][0]['valueSetString'].sub 'urn:oid:', '' } || []
      valueset_urls = valueset_urls.flatten.compact.uniq unless valueset_urls.nil?
      valueset_urls
    end

    def get_all_dependent_valuesets(library, measurebundle)
      all_dependent_valuesets = []
      to_process = Queue.new
      processed = Set.new
      to_process << library['resource']['id']
      until to_process.empty?
        library_id = to_process.pop
        next if processed.include? library_id

        processed << library_id
        get_valueset_urls(get_library_by_id(measurebundle, library_id)).each { |url| all_dependent_valuesets << url }
        get_related_libraries(library).each { |lib_id| to_process << lib_id }
      end

      all_dependent_valuesets
    end
  end
end
