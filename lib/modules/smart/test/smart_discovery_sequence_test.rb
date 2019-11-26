# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::SMARTDiscoverySequence do
  before do
    @sequence_class = Inferno::Sequence::SMARTDiscoverySequence
    @instance = Inferno::Models::TestingInstance.new
  end

  describe 'required well-known configuration fields' do
    before do
      @test = @sequence_class[:required_well_known_fields]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips when no well-known configuration has been found' do
      assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }
    end
  end

  describe 'recommended well-known configuration fields' do
    before do
      @test = @sequence_class[:recommended_well_known_fields]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips when no well-known configuration has been found' do
      assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }
    end
  end
end
