# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCoreR4ClinicalNotesSequence do
  before do
    @sequence_class = Inferno::Sequence::USCoreR4ClinicalNotesSequence

    @patient_ids = '1234'
    @docref_bundle = FHIR.from_contents(load_fixture(:clinicalnotes_docref_bundle))
    @diagrpt_bundle = FHIR.from_contents(load_fixture(:clinicalnotes_diagrpt_bundle))

    @instance = Inferno::TestingInstance.create(
      url: 'http://www.example.com'
    )
    @instance.patient_ids = @patient_ids

    @client = FHIR::Client.new(@instance.url)
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
      assert @sequence.document_attachments.keys.any?
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
      assert @sequence.report_attachments.keys.any?
    end
  end

  describe 'Server requires status tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_clinical_notes]
      @resource_class = 'DocumentReference'
      @query_url = "#{@instance.url}/#{@resource_class}"
      @search_params = { 'patient': @instance.patient_ids }
    end

    it 'fails with http status 4xx' do
      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 401
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Bad response code/, error.message)
    end

    it 'fails with http status 400 without OperationOutcome' do
      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 400,
          body: FHIR::Bundle.new.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert error.message == 'Server returned a status of 400 without an OperationOutcome.'
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
  end

  describe 'Clinical Notes tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_clinical_notes]
      @search_params = { 'patient': @instance.patient_ids }
    end

    it 'passes with correct DocumentReference and DiagnosticReport in Bundle' do
      stub_request(:get, "#{@instance.url}/DocumentReference")
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: @docref_bundle.to_json
        )

      stub_request(:get, "#{@instance.url}/DiagnosticReport")
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: @diagrpt_bundle.to_json
        )

      @sequence.run_test(@test)
      assert @sequence.document_attachments.keys.any?
    end
  end

  describe 'DocumentReference tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_clinical_notes]
      @query_url = "#{@instance.url}/DocumentReference"
      @search_params = { 'patient': @instance.patient_ids }

      stub_request(:get, "#{@instance.url}/DiagnosticReport")
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: @diagrpt_bundle.to_json
        )
    end

    it 'skips when DocumentReference does not have Consultation Note' do
      code = '11488-4'
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.reject { |item| item.resource.type.coding[0].code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DocumentReference types #{code}/, error.message)
    end

    it 'skips when DocumentReference does not have Discharge Summary' do
      code = '18842-5'
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.reject { |item| item.resource.type.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DocumentReference types #{code}/, error.message)
    end

    it 'skips when DocumentReference does not have History & Physical Note' do
      code = '34117-2'
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.reject { |item| item.resource.type.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DocumentReference types #{code}/, error.message)
    end

    it 'skips when DocumentReference does not have Procedure Note' do
      code = '28570-0'
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.reject { |item| item.resource.type.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DocumentReference types #{code}/, error.message)
    end

    it 'skips when DocumentReference does not have Progress Note' do
      code = '11506-3'
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.reject { |item| item.resource.type.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DocumentReference types #{code}/, error.message)
    end

    it 'skips when DocumentReference does not have more than one types' do
      code = ['11488-4', '11506-3']
      source = FHIR::Bundle.new
      source.entry = @docref_bundle.entry.select { |item| code.exclude?(item.resource.type.coding.first.code) }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DocumentReference types #{code.join(', ')}/, error.message)
    end
  end

  describe 'DiagnosticReport tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_clinical_notes]
      @query_url = "#{@instance.url}/DiagnosticReport"
      @search_params = { 'patient': @instance.patient_ids }

      stub_request(:get, "#{@instance.url}/DocumentReference")
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: @docref_bundle.to_json
        )
    end

    it 'skips when DiagnosticReport does not have Cardiology' do
      code = 'LP29708-2'
      source = FHIR::Bundle.new
      source.entry = @diagrpt_bundle.entry.reject { |item| item.resource.category.first.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DiagnosticReport categories #{code}/, error.message)
    end

    it 'skips when DiagnosticReport does not have Pathology' do
      code = 'LP7839-6'
      source = FHIR::Bundle.new
      source.entry = @diagrpt_bundle.entry.reject { |item| item.resource.category.first.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DiagnosticReport categories #{code}/, error.message)
    end

    it 'skips when DiagnosticReport does not have Radiology' do
      code = 'LP29684-5'
      source = FHIR::Bundle.new
      source.entry = @diagrpt_bundle.entry.reject { |item| item.resource.category.first.coding.first.code == code }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DiagnosticReport categories #{code}/, error.message)
    end

    it 'skips when DiagnosticReport does not more than one categories' do
      code = ['LP29708-2', 'LP29684-5']
      source = FHIR::Bundle.new
      source.entry = @diagrpt_bundle.entry.select { |item| code.exclude?(item.resource.category.first.coding.first.code) }

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/ DiagnosticReport categories #{code.join(', ')}/, error.message)
    end

    it 'pass when one DiagnosticReport instance has more than one categories' do
      code = 'LP29684-5' # Radiology
      source = FHIR::Bundle.new
      radiology_report = @diagrpt_bundle.entry.select { |item| item.resource.category.first.coding.first.code == code }
      source.entry = @diagrpt_bundle.entry - radiology_report
      source.entry.first.resource.category << radiology_report.first.resource.category.first

      stub_request(:get, @query_url)
        .with(query: @search_params)
        .to_return(
          status: 200,
          body: source.to_json
        )

      @sequence.test_clinical_notes
    end
  end

  describe 'Matched Attachments tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:have_matched_attachments]
      @sequence.document_attachments = {
        '1234' => {
          '/Binary/SMART-Binary-1-note' => 'SMART-DocumentReference-1-note',
          '/Binary/SMART-Binary-2-note' => 'SMART-DocumentReference-2-note'
        }
      }
      @sequence.report_attachments = {
        '1234' => {
          '/Binary/SMART-Binary-1-note' => 'SMART-DiagnosticReport-1-note',
          '/Binary/SMART-Binary-2-note' => 'SMART-DiagnosticReport-2-note'
        }
      }
    end

    it 'skips if skip_document_reference is true' do
      @sequence.document_attachments.clear

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/^There is no attachment in DocumentReference/, error.message)
    end

    it 'skips if report_attachments is empty' do
      @sequence.report_attachments.clear

      error = assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end

      assert_match(/^There is no attachment in DiagnosticReport/, error.message)
    end

    it 'fails if one attachment does not have a match' do
      @sequence.document_attachments['1234'].delete('/Binary/SMART-Binary-2-note')

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_equal 'Attachments /Binary/SMART-Binary-2-note in DiagnosticReport/SMART-DiagnosticReport-2-note for Patient 1234 are not referenced in any DocumentReference.', error.message
    end

    it 'passes if all attachments are matched' do
      @sequence.run_test(@test)
    end
  end
end
