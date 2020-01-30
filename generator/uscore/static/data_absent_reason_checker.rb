# frozen_string_literal: true

module DataAbsentReasonChecker
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
    body.include? 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
  end

  def contains_data_absent_code?(body)
    body.include? 'http://terminology.hl7.org/CodeSystem/data-absent-reason'
  end
end
