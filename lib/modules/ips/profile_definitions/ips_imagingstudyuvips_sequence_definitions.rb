# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsImagingstudyuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'ImagingStudy'
          },
          {
            path: 'identifier'
          },
          {
            path: 'subject'
          },
          {
            path: 'subject.reference'
          },
          {
            path: 'started'
          },
          {
            path: 'procedureCode'
          },
          {
            path: 'reasonCode'
          },
          {
            path: 'series'
          },
          {
            path: 'series.uid'
          },
          {
            path: 'series.modality'
          },
          {
            path: 'series.instance'
          },
          {
            path: 'series.instance.uid'
          },
          {
            path: 'series.instance.sopClass'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
