# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310CareplanSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310CareplanSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'CarePlan')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @query = {
        'patient': @instance.patient_id,
        'category': 'assess-plan'
      }
    end

    it 'skips if the CarePlan search interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support CarePlan search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query)
        .to_return(status: 401)

      @sequence.run_test(@test)
    end

    it 'is omitted when no token is set' do
      @instance.token = ''

      exception = assert_raises(Inferno::OmitException) { @sequence.run_test(@test) }

      assert_equal 'Do not test if no bearer token set', exception.message
    end
  end

  describe 'CarePlan search by patient+category test' do
    before do
      @test = @sequence_class[:search_by_patient_category]
      @sequence = @sequence_class.new(@instance, @client)
      @care_plan = FHIR.from_contents(load_fixture(:us_core_careplan))
      @care_plan_ary = [@care_plan]
      @sequence.instance_variable_set(:'@care_plan', @care_plan)
      @sequence.instance_variable_set(:'@care_plan_ary', @care_plan_ary)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'category'))
      }
    end

    it 'fails if a non-success response code is received' do
      ['assess-plan'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/CarePlan")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 401)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      ['assess-plan'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/CarePlan")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::CarePlan.new.to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: CarePlan', exception.message
    end

    it 'skips if an empty Bundle is received' do
      ['assess-plan'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/CarePlan")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::Bundle.new.to_json)
      end

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No resources appear to be available for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      ['assess-plan'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        stub_request(:get, "#{@base_url}/CarePlan")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::CarePlan.new(id: '!@#$%')).to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      ['assess-plan'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'category': value
        }
        body =
          if @sequence.resolve_element_from_path(@care_plan, 'category.coding.code') == value
            wrap_resources_in_bundle(@care_plan_ary).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/CarePlan")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
    end
  end

  describe 'CarePlan search by patient+category+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_date]
      @sequence = @sequence_class.new(@instance, @client)
      @care_plan = FHIR.from_contents(load_fixture(:us_core_careplan))
      @care_plan_ary = [@care_plan]
      @sequence.instance_variable_set(:'@care_plan', @care_plan)
      @sequence.instance_variable_set(:'@care_plan_ary', @care_plan_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'category')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'period'))
      }
    end

    it 'skips if no CarePlan resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No resources appear to be available for this patient. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@care_plan_ary', [FHIR::CarePlan.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::CarePlan.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: CarePlan', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::CarePlan.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end
  end

  describe 'CarePlan search by patient+category+status+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_status_date]
      @sequence = @sequence_class.new(@instance, @client)
      @care_plan = FHIR.from_contents(load_fixture(:us_core_careplan))
      @care_plan_ary = [@care_plan]
      @sequence.instance_variable_set(:'@care_plan', @care_plan)
      @sequence.instance_variable_set(:'@care_plan_ary', @care_plan_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'category')),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'status')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'period'))
      }
    end

    it 'skips if no CarePlan resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No resources appear to be available for this patient. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@care_plan_ary', [FHIR::CarePlan.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::CarePlan.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: CarePlan', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::CarePlan.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end
  end

  describe 'CarePlan search by patient+category+status test' do
    before do
      @test = @sequence_class[:search_by_patient_category_status]
      @sequence = @sequence_class.new(@instance, @client)
      @care_plan = FHIR.from_contents(load_fixture(:us_core_careplan))
      @care_plan_ary = [@care_plan]
      @sequence.instance_variable_set(:'@care_plan', @care_plan)
      @sequence.instance_variable_set(:'@care_plan_ary', @care_plan_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'category')),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_plan_ary, 'status'))
      }
    end

    it 'skips if no CarePlan resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No resources appear to be available for this patient. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@care_plan_ary', [FHIR::CarePlan.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::CarePlan.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: CarePlan', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::CarePlan.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/CarePlan")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@care_plan_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'CarePlan read test' do
    before do
      @care_plan_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@care_plan', FHIR::CarePlan.new(id: @care_plan_id))
    end

    it 'skips if the CarePlan read interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support CarePlan read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no CarePlan has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No CarePlan resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'CarePlan',
        resource_id: @care_plan_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CarePlan/#{@care_plan_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'CarePlan',
        resource_id: @care_plan_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CarePlan/#{@care_plan_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected CarePlan resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a CarePlan' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'CarePlan',
        resource_id: @care_plan_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CarePlan/#{@care_plan_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type CarePlan.', exception.message
    end

    it 'succeeds when a CarePlan resource is read successfully' do
      care_plan = FHIR::CarePlan.new(
        id: @care_plan_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'CarePlan',
        resource_id: @care_plan_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CarePlan/#{@care_plan_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: care_plan.to_json)

      @sequence.run_test(@test)
    end
  end
end
