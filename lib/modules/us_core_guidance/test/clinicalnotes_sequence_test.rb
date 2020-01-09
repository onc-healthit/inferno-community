# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCoreR4ClinicalNotesSequence do
  before do
    @sequence_class = Inferno::Sequence::USCoreR4ClinicalNotesSequence

    @patient_id = 1234
    @docref_bundle = FHIR.from_contents(load_fixture(:clinicalnotes_docref_bundle))
    @diagrpt_bundle = FHIR.from_contents(load_fixture(:clinicalnotes_diagrpt_bundle))

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com'
    )
    @instance.patient_id = @patient_id

    @client = FHIR::Client.new(@instance.url)
  end

  def self.it_tests_failed_return
    it 'fails with http status 4xx' do
      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 400
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Bad response code/, error.message)
    end

    it 'fails if returned resource is not Bundle' do
      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: FHIR::DocumentReference.new.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Expected FHIR Bundle but found/, error.message)
    end

    it 'skips with empty bundle' do
      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: FHIR::Bundle.new.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/^This patient does not have #{@resource_class} with (type|category) #{@category_code}/, error.message)
    end
  end

  def self.it_tests_required_docref
    it 'passes with correct DocumentReference in Bundle' do
      code = @category_code.split('|')[1]
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.select { |item| item.resource.type.coding[0].code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      @sequence.run_test(@test)
      assert @sequence.document_attachments.attachment.keys.any?
    end
  end

  def self.it_tests_required_diagrpt
    it 'passes with correct DiagnosticReport in Bundle' do
      code = @category_code.split('|')[1]
      source = FHIR::Bundle.new
      source.entry = @diagrpt_bundle.entry.select { |item| item.resource.category[0].coding[0].code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      @sequence.run_test(@test)
      assert @sequence.report_attachments.attachment.keys.any?
    end
  end

  describe 'Consultation Note tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_consultation_note]
      @category_code = 'http://loinc.org|11488-4'
      @resource_class = 'DocumentReference'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'type': @category_code }
    end

    it_tests_failed_return
    it_tests_required_docref
  end

  describe 'Discharge Summary tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_discharge_summary]
      @category_code = 'http://loinc.org|18842-5'
      @resource_class = 'DocumentReference'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'type': @category_code }
    end

    it_tests_failed_return
    it_tests_required_docref
  end

  describe 'History and Physical Note tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_history_note]
      @category_code = 'http://loinc.org|34117-2'
      @resource_class = 'DocumentReference'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'type': @category_code }
    end

    it_tests_failed_return
    it_tests_required_docref
  end

  describe 'Procedures Note tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_procedures_note]
      @category_code = 'http://loinc.org|28570-0'
      @resource_class = 'DocumentReference'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'type': @category_code }
    end

    it_tests_failed_return
    it_tests_required_docref
  end

  describe 'Progress Note tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_progress_note]
      @category_code = 'http://loinc.org|11506-3'
      @resource_class = 'DocumentReference'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'type': @category_code }
    end

    it_tests_failed_return
    it_tests_required_docref
  end

  describe 'Cardioogy Report tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_cardiology_report]
      @category_code = 'http://loinc.org|LP29708-2'
      @resource_class = 'DiagnosticReport'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'category': @category_code }
    end

    it_tests_failed_return
    it_tests_required_diagrpt
  end

  describe 'Pathology Report tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_pathology_report]
      @category_code = 'http://loinc.org|LP7839-6'
      @resource_class = 'DiagnosticReport'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'category': @category_code }
    end

    it_tests_failed_return
    it_tests_required_diagrpt
  end

  describe 'Radiology Report tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_radiology_report]
      @category_code = 'http://loinc.org|LP29684-5'
      @resource_class = 'DiagnosticReport'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_id, 'category': @category_code }
    end

    it_tests_failed_return
    it_tests_required_diagrpt
  end

  describe 'Matched Attachments tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_matched_attachments]
      @sequence.document_attachments = Inferno::Sequence::ClinicalNoteAttachment.new('DocumentReference')
      @sequence.document_attachments.attachment['/Binary/SMART-Binary-1-note'] = 'SMART-DiagnosticReport-1-note'
      @sequence.document_attachments.attachment['/Binary/SMART-Binary-2-note'] = 'SMART-DiagnosticReport-2-note'
      @sequence.report_attachments = Inferno::Sequence::ClinicalNoteAttachment.new('DiagnosticReport')
      @sequence.report_attachments.attachment['/Binary/SMART-Binary-1-note'] = 'SMART-DiagnosticReport-1-note'
      @sequence.report_attachments.attachment['/Binary/SMART-Binary-2-note'] = 'SMART-DiagnosticReport-2-note'
    end

    it 'skips if skip_document_reference is true' do
      @sequence.skip_document_reference = true

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Not all required Clinical Notes appear to be available for this patient/, error.message)
    end

    it 'skips if skip_diagnostic_report is true' do
      @sequence.skip_diagnostic_report = true

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Not all required Clinical Notes appear to be available for this patient/, error.message)
    end

    it 'fails if one attachment does not have a match' do
      @sequence.report_attachments.attachment.delete('/Binary/SMART-Binary-2-note')

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_equal 'Attachments /Binary/SMART-Binary-2-note in DocumentReference/SMART-DiagnosticReport-2-note are not referenced in any DiagnosticReport.', error.message
    end

    it 'passes if all attachments are matched' do
      @sequence.run_test(@test)
    end
  end
end
