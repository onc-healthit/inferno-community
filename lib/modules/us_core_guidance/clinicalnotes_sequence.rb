# frozen_string_literal: true

module Inferno
  module Sequence
    class ClinicalNoteAttachment
      attr_reader :resource_class
      attr_reader :attachment

      def initialize(resource_class)
        @resource_class = resource_class
        @attachment = {}
      end
    end

    class USCoreR4ClinicalNotesSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Clinical Notes Guideline Tests'

      description 'Verify that DocumentReference and DiagnosticReport resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCCN'

      requires :token, :patient_id
      conformance_supports :DocumentReference, :DiagnosticReport

      details %(

        The #{title} Sequence tests DiagnosticReport and DocumentReference resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [US Core Clinical Notes Guidance](https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html)

        In this set of tests, Inferno serves as a FHIR client that attempts to access different types of Clinical Notes
        specified in the Guidance. The provided patient needs to have the following five common clinical notes as DocumentReference resources:

        * Consultation Note (11488-4)
        * Discharge Summary (18842-5)
        * History & Physical Note (34117-2)
        * Procedures Note (28570-0)
        * Progress Note (11506-3)

        The provided patient also need to have the following three common diagnostic reports as DiagnosticReport resources:

        * Cardiology (LP29708-2)
        * Pathology (LP7839-6)
        * Radiology (LP29684-5)

        In order to enable consistent access to scanned narrative-only clinical reports,
        the US Core server shall expose these reports through both
        DiagnosticReport and DocumentReference by representing the same attachment url.
      )

      attr_accessor :document_attachments, :report_attachments

      def test_clinical_notes_document_reference(category_code)
        search_params = { 'patient': @instance.patient_id, 'type': category_code }
        resource_class = 'DocumentReference'

        skip_if_known_not_supported(:DocumentReference, [:read])

        reply = get_resource_by_params(versioned_resource_class(resource_class), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == resource_class }

        skip "No #{resource_class} resources with type #{category_code} appear to be available. Please use patients with more information." unless resources_found

        self.document_attachments = ClinicalNoteAttachment.new(resource_class) if document_attachments.nil?

        document_references = fetch_all_bundled_resources(reply.resource)

        document_references&.each do |document|
          document&.content&.select { |content| !document_attachments.attachment.key?(content&.attachment&.url) }&.each do |content|
            document_attachments.attachment[content.attachment.url] = document.id
          end
        end
      end

      def test_clinical_notes_diagnostic_report(category_code)
        search_params = { 'patient': @instance.patient_id, 'category': category_code }
        resource_class = 'DiagnosticReport'

        reply = get_resource_by_params(versioned_resource_class(resource_class), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == resource_class }

        skip "No #{resource_class} resources with category #{category_code} appear to be available. Please use patients with more information." unless resources_found

        self.report_attachments = ClinicalNoteAttachment.new(resource_class) if report_attachments.nil?

        diagnostic_reports = fetch_all_bundled_resources(reply.resource)

        diagnostic_reports&.each do |report|
          report&.presentedForm&.select { |attachment| !report_attachments.attachment.key?(attachment&.url) }&.each do |attachment|
            report_attachments.attachment[attachment.url] = report.id
          end
        end
      end

      test :have_consultation_note do
        metadata do
          id '01'
          name 'Server shall have Consultation Note from DocumentReference search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|11488-4')
      end

      test :have_discharge_summary do
        metadata do
          id '02'
          name 'Server shall have Discharge Summary from DocumentReference search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|18842-5')
      end

      test :have_history_note do
        metadata do
          id '03'
          name 'Server shall have History and Physical Note from DocumentReference search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|34117-2')
      end

      test :have_procedures_note do
        metadata do
          id '04'
          name 'Server returns Procedures Note from DocumentReference search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|28570-0')
      end

      test :have_progress_note do
        metadata do
          id '05'
          name 'Server returns Progress Note from DocumentReference search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|11506-3')
      end

      test :have_cardiology_report do
        metadata do
          id '06'
          name 'Server returns Cardiology report from DiagnosticReport search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP29708-2')
      end

      test :have_pathology_report do
        metadata do
          id '07'
          name 'Server returns Pathology report from DiagnosticReport search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP7839-6')
      end

      test :have_radiology_report do
        metadata do
          id '08'
          name 'Server returns Radiology report from DiagnosticReport search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP29684-5')
      end

      test :have_matched_attachments do
        metadata do
          id '09'
          name 'DiagnosticReport and DocumentReference reference the same attachment'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
            All presentedForms urls referenced in DiagnosticReports shall have corresponding content attachment urls referenced in DocumentReference
          )
          versions :r4
        end

        skip 'There is no attachement in DocumentReference. Please select another patient.' unless document_attachments&.attachment&.any?
        skip 'There is no attachement in DiagnosticReport. Please select another patient.' unless report_attachments&.attachment&.any?

        assert_attachment_matched(report_attachments, document_attachments)
      end

      def assert_attachment_matched(source_attachments, target_attachments)
        not_matched_urls = source_attachments.attachment.keys - target_attachments.attachment.keys
        not_matched_attachments = not_matched_urls.map { |url| "#{url} in #{source_attachments.resource_class}/#{source_attachments.attachment[url]}" }

        assert not_matched_attachments.empty?, "Attachments #{not_matched_attachments.join(', ')} are not referenced in any #{target_attachments.resource_class}."
      end
    end
  end
end
