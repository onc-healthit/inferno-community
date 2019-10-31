# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::UsCoreR4CapabilityStatementSequence do
  before do
    @sequence_class = Inferno::Sequence::UsCoreR4CapabilityStatementSequence
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.new(oauth_token_endpoint: @token_endpoint, scopes: 'jkl')
    @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'r4'))
  end

  # TODO: check assertion error messages
  describe 'JSON support test' do
    before do
      @test = @sequence_class[:json_support]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'fails when the CapabilityStatement is invalid' do
      @sequence.instance_variable_set(:'@conformance', FHIR::DSTU2::Conformance.new)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected valid CapabilityStatement resource.', exception.message
    end

    it 'fails when the CapabilityStatement has no JSON support' do
      @sequence.instance_variable_set(:'@conformance', FHIR::CapabilityStatement.new)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Conformance does not state support for json.', exception.message
    end

    it 'succeeds when the CapabilityStatement has JSON support' do
      @sequence.instance_variable_set(:'@conformance', FHIR::CapabilityStatement.new(format: ['application/fhir+json']))

      @sequence.run_test(@test)
    end
  end

  describe 'Profile support test' do
    before do
      @test = @sequence_class[:profile_support]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@conformance', FHIR::CapabilityStatement.new)
    end

    it 'fails when the CapabilityStatement is invalid' do
      @sequence.instance_variable_set(:'@conformance', FHIR::DSTU2::Conformance.new)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected valid CapabilityStatement resource.', exception.message
    end

    it 'fails when the CapabilityStatement has no Patient support' do
      @sequence.instance_variable_set(:'@server_capabilities', OpenStruct.new(supported_resources: ['Observation']))

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'US Core Patient profile not supported', exception.message
    end

    it 'fails when the CapabilityStatement has only Patient support' do
      @sequence.instance_variable_set(:'@server_capabilities', OpenStruct.new(supported_resources: ['Patient']))

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal 'No US Core resources other than Patient are supported', exception.message
    end

    it 'generates a warning when the CapabilityStatement does not claim support for a US Core Profile' do
      supported_resources = ['Patient', 'Condition']
      @sequence.instance_variable_set(
        :'@server_capabilities',
        OpenStruct.new(supported_resources: supported_resources)
      )

      @sequence.run_test(@test)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      supported_resources.each do |resource|
        profile = @sequence_class::PROFILES[resource].first
        warning_message = "CapabilityStatement does not claim support for US Core #{resource} profile: #{profile}"

        assert_includes(warnings, warning_message)
      end
    end

    it 'succeeds without warnings when multiple US Core resources support all US Core profiles' do
      supported_resources = ['Patient', 'Condition']
      supported_profiles = supported_resources.map { |resource| @sequence_class::PROFILES[resource].first }
      @sequence.instance_variable_set(
        :'@server_capabilities',
        OpenStruct.new(supported_resources: supported_resources, supported_profiles: supported_profiles)
      )

      @sequence.run_test(@test)

      warnings = @sequence.instance_variable_get(:'@test_warnings')

      assert warnings.blank?
    end
  end
end
