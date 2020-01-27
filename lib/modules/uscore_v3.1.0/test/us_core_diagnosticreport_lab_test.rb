# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310DiagnosticreportLabSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310DiagnosticreportLabSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'DiagnosticReport')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'DiagnosticReport search by patient+category test' do
    before do
      @test = @sequence_class[:search_by_patient_category]
      @sequence = @sequence_class.new(@instance, @client)
      @diagnostic_report = FHIR.from_contents(load_fixture(:us_core_diagnosticreport_lab))
      @diagnostic_report_ary = [@diagnostic_report]
      @sequence.instance_variable_set(:'@diagnostic_report', @diagnostic_report)
      @sequence.instance_variable_set(:'@diagnostic_report_ary', @diagnostic_report_ary)

      @query = {
        'patient': 'patient',
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'category'))
      }
    end

    it 'fails if a non-success response code is received' do
      ['LAB'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 401)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      ['LAB'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
    end

    it 'skips if an empty Bundle is received' do
      ['LAB'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::Bundle.new.to_json)
      end

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DiagnosticReport resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      ['LAB'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DiagnosticReport.new(id: '!@#$%')).to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      ['LAB'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        body =
          if @sequence.resolve_element_from_path(@diagnostic_report, 'category.coding.code') == value
            wrap_resources_in_bundle(@diagnostic_report_ary).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        ['LAB'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'category': value
          }
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        ['LAB'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'category': value
          }
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        end

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        ['LAB'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'category': value
          }
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 500)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        ['LAB'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'category': value
          }
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        ['LAB'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'category': value
          }
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/DiagnosticReport")
            .with(query: query_params.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: wrap_resources_in_bundle([@diagnostic_report]).to_json)
        end

        @sequence.run_test(@test)
      end
    end
  end

  describe 'DiagnosticReport search by patient test' do
    before do
      @test = @sequence_class[:search_by_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @diagnostic_report = FHIR.from_contents(load_fixture(:us_core_diagnosticreport_lab))
      @diagnostic_report_ary = [@diagnostic_report]
      @sequence.instance_variable_set(:'@diagnostic_report', @diagnostic_report)
      @sequence.instance_variable_set(:'@diagnostic_report_ary', @diagnostic_report_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient'
      }
    end

    it 'skips if no DiagnosticReport resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DiagnosticReport resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DiagnosticReport.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@diagnostic_report_ary).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@diagnostic_report]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'DiagnosticReport search by patient+code test' do
    before do
      @test = @sequence_class[:search_by_patient_code]
      @sequence = @sequence_class.new(@instance, @client)
      @diagnostic_report = FHIR.from_contents(load_fixture(:us_core_diagnosticreport_lab))
      @diagnostic_report_ary = [@diagnostic_report]
      @sequence.instance_variable_set(:'@diagnostic_report', @diagnostic_report)
      @sequence.instance_variable_set(:'@diagnostic_report_ary', @diagnostic_report_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'code'))
      }
    end

    it 'skips if no DiagnosticReport resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DiagnosticReport resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@diagnostic_report_ary', [FHIR::DiagnosticReport.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DiagnosticReport.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@diagnostic_report_ary).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@diagnostic_report]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'DiagnosticReport search by patient+category+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_date]
      @sequence = @sequence_class.new(@instance, @client)
      @diagnostic_report = FHIR.from_contents(load_fixture(:us_core_diagnosticreport_lab))
      @diagnostic_report_ary = [@diagnostic_report]
      @sequence.instance_variable_set(:'@diagnostic_report', @diagnostic_report)
      @sequence.instance_variable_set(:'@diagnostic_report_ary', @diagnostic_report_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'category')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'effective'))
      }
    end

    it 'skips if no DiagnosticReport resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DiagnosticReport resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@diagnostic_report_ary', [FHIR::DiagnosticReport.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DiagnosticReport.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
      end
    end
  end

  describe 'DiagnosticReport search by patient+status test' do
    before do
      @test = @sequence_class[:search_by_patient_status]
      @sequence = @sequence_class.new(@instance, @client)
      @diagnostic_report = FHIR.from_contents(load_fixture(:us_core_diagnosticreport_lab))
      @diagnostic_report_ary = [@diagnostic_report]
      @sequence.instance_variable_set(:'@diagnostic_report', @diagnostic_report)
      @sequence.instance_variable_set(:'@diagnostic_report_ary', @diagnostic_report_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'status'))
      }
    end

    it 'skips if no DiagnosticReport resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DiagnosticReport resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@diagnostic_report_ary', [FHIR::DiagnosticReport.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DiagnosticReport.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@diagnostic_report_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DiagnosticReport search by patient+code+date test' do
    before do
      @test = @sequence_class[:search_by_patient_code_date]
      @sequence = @sequence_class.new(@instance, @client)
      @diagnostic_report = FHIR.from_contents(load_fixture(:us_core_diagnosticreport_lab))
      @diagnostic_report_ary = [@diagnostic_report]
      @sequence.instance_variable_set(:'@diagnostic_report', @diagnostic_report)
      @sequence.instance_variable_set(:'@diagnostic_report_ary', @diagnostic_report_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'code')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@diagnostic_report_ary, 'effective'))
      }
    end

    it 'skips if no DiagnosticReport resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DiagnosticReport resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@diagnostic_report_ary', [FHIR::DiagnosticReport.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DiagnosticReport")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DiagnosticReport.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/DiagnosticReport")
          .with(query: @query.merge('status': ['registered,partial,preliminary,final,amended,corrected,appended,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::DiagnosticReport.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: DiagnosticReport', exception.message
      end
    end
  end
end
