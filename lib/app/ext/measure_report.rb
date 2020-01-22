# frozen_string_literal: true

module FHIR
  module STU3
    class MeasureReport
      FHIR::STU3::MeasureReport::METADATA['_type'] = { 'type' => 'code', 'path' => 'MeasureReport._type', 'min' => 0, 'max' => 1 }

      attr_accessor :_type
    end
  end
end
