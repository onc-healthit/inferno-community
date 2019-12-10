# frozen_string_literal: true

require_relative '../../../../../test/test_helper'

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
    end

    it 'fails when a required scope is missing' do
      @sequence.required_scopes.each do |scope|
        scopes = @sequence.required_scopes - [scope]
        @instance.instance_variable_set(:@received_scopes, scopes.join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Required scopes missing: #{scope}", exception.message
      end
    end

    it 'fails when there is no patient-level scope' do
      @instance.instance_variable_set(:@received_scopes, @sequence.required_scopes.join(' '))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Must contain a patient-level scope in the format: patient/[ resource | * ].[ read | *].', exception.message
    end

    it 'fails when there is a badly formatted scope' do
      bad_scopes = ['patient/*/*', 'user/*.read', 'patient/*.*.*', 'patient/*.write']
      bad_scopes.each do |scope|
        @instance.instance_variable_set(:@received_scopes, (@sequence.required_scopes + [scope]).join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Scope '#{scope}' does not follow the format: patient/[ resource | * ].[ read | * ]", exception.message
      end

      bad_resource_type = 'ValueSet'
      @instance.instance_variable_set(:@received_scopes, (@sequence.required_scopes + ["patient/#{bad_resource_type}.*"]).join(' '))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "'#{bad_resource_type}' must be either a valid resource type or '*'", exception.message
    end

    it 'succeeds when the required scopes and a patient-level scope are present' do
      @instance.instance_variable_set(:@received_scopes, (@sequence.required_scopes + ['patient/*.*']).join(' '))

      @sequence.run_test(@test)
    end
  end
end
