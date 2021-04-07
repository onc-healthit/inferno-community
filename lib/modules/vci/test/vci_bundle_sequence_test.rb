# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::VciBundleSequence do
  before do
    @sequence_class = Inferno::Sequence::VciBundleSequence
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'ips')
    @client = FHIR::Client.for_testing_instance(@instance)
    @bundle = FHIR.from_contents(load_fixture('example-00-a-fhirBundle'))
    @instance.vci_bundle_json = @bundle.to_json
  end

  describe 'Bundle Validation' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'validates using AD profiles' do
      test = @sequence_class[:resource_validate_bundle]

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(test) }

      assert_match(/Bundle.entry failed cardinality test \(1\.\.1\)/, exception.message)
    end

    it 'validates using DM profiles' do
      test = @sequence_class[:resource_validate_bundle_dm]

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(test) }

      assert_match(/Bundle.entry failed cardinality test \(1\.\.1\)/, exception.message)
    end
  end
end
