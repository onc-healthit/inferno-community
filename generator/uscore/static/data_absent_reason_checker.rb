# frozen_string_literal: true

module Inferno
  module DataAbsentReasonChecker
    DAR_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
    DAR_CODE_SYSTEM_URL = 'http://terminology.hl7.org/CodeSystem/data-absent-reason'

    def check_for_data_absent_reasons
      proc do |reply|
        if !@instance.data_absent_extension_found && contains_data_absent_extension?(reply.body)
          @instance.data_absent_extension_found = true
          @instance.save
        end

        if !@instance.data_absent_code_found && contains_data_absent_code?(reply.body)
          @instance.data_absent_code_found = true
          @instance.save
        end
      end
    end

    def contains_data_absent_extension?(body)
      body.include? DAR_EXTENSION_URL
    end

    def contains_data_absent_code?(body)
      if body.include? DAR_CODE_SYSTEM_URL
        resource = FHIR.from_contents(body)
        walk_resource(resource) do |element, meta, _path|
          next unless meta['type'] == 'Coding'

          return true if element.code == 'unknown' && element.system == DAR_CODE_SYSTEM_URL
        end
      end

      false
    end
  end
end
