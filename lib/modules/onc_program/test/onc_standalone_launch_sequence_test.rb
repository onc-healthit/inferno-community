# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::OncStandaloneLaunchSequence do
  before do
    @sequence_class = Inferno::Sequence::OncStandaloneLaunchSequence
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.new
  end

  describe 'ONC scopes test' do
    before do
      @test = @sequence_class[:onc_scopes]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
    end

    let(:good_scopes) { @sequence.required_scopes.join(' ') + ' patient/*.*' }

    it 'skips when the launch failed' do
      @sequence.instance_variable_set(:@params, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'fails when a required scope was not requested' do
      @sequence.required_scopes.each do |scope|
        scopes = @sequence.required_scopes - [scope]
        @instance.instance_variable_set(:@onc_sl_scopes, scopes.join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Required scopes were not requested: #{scope}", exception.message
      end
    end

    it 'fails when a required scope was not received' do
      @instance.instance_variable_set(:@onc_sl_scopes, good_scopes)
      @sequence.required_scopes.each do |scope|
        scopes = @sequence.required_scopes - [scope]
        @instance.instance_variable_set(:@received_scopes, scopes.join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Required scopes were not received: #{scope}", exception.message
      end
    end

    it 'fails when no patient-level scope was requested' do
      @instance.instance_variable_set(:@onc_sl_scopes, @sequence.required_scopes.join(' '))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Patient-level scope in the format: patient/[ resource | * ].[ read | *] was not requested.', exception.message
    end

    it 'fails when no patient-level scope was received' do
      @instance.instance_variable_set(:@onc_sl_scopes, good_scopes)
      @instance.instance_variable_set(:@received_scopes, @sequence.required_scopes.join(' '))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Patient-level scope in the format: patient/[ resource | * ].[ read | *] was not received.', exception.message
    end

    it 'fails when a badly formatted scope was requested' do
      bad_scopes = ['patient/*/*', 'user/*.read', 'patient/*.*.*', 'patient/*.write']
      bad_scopes.each do |scope|
        @instance.instance_variable_set(:@onc_sl_scopes, (@sequence.required_scopes + [scope]).join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Requested scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]", exception.message
      end

      bad_resource_type = 'ValueSet'
      @instance.instance_variable_set(:@received_scopes, good_scopes)
      @instance.instance_variable_set(:@onc_sl_scopes, @sequence.required_scopes.join(' ') + " patient/#{bad_resource_type}.*")
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "'#{bad_resource_type}' must be either a valid resource type or '*'", exception.message
    end

    it 'fails when a badly formatted scope was received' do
      bad_scopes = ['patient/*/*', 'user/*.read', 'patient/*.*.*', 'patient/*.write']
      @instance.instance_variable_set(:@onc_sl_scopes, good_scopes)

      bad_scopes.each do |scope|
        @instance.instance_variable_set(:@received_scopes, (@sequence.required_scopes + [scope]).join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Received scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]", exception.message
      end

      bad_resource_type = 'ValueSet'
      @instance.instance_variable_set(:@received_scopes, @sequence.required_scopes.join(' ') + " patient/#{bad_resource_type}.*")
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "'#{bad_resource_type}' must be either a valid resource type or '*'", exception.message
    end

    it 'succeeds when the required scopes and a patient-level scope are present' do
      @instance.instance_variable_set(:@onc_sl_scopes, good_scopes)
      @instance.instance_variable_set(:@received_scopes, good_scopes)

      @sequence.run_test(@test)
    end
  end

  describe 'unauthorized read test' do
    before do
      @test = @sequence_class[:unauthorized_read]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
      @instance.save
      @instance.update(
        token: 'TOKEN',
        url: 'http://www.example.com/fhir'
      )
      @instance.patient_id = '123'
    end

    it 'skips when the launch failed' do
      @sequence.instance_variable_set(:@params, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'fails when the read does not return a 401' do
      stub_request(:get, "#{@instance.url}/Patient/#{@instance.patient_id}")
        .with { |request| !request.headers.key? 'Authorization' }
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the read returns a 401' do
      stub_request(:get, "#{@instance.url}/Patient/#{@instance.patient_id}")
        .with { |request| !request.headers.key? 'Authorization' }
        .to_return(status: 401)

      @sequence.run_test(@test)
    end
  end
end
