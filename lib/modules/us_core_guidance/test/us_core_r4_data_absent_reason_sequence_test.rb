# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCoreR4DataAbsentReasonSequence do
  before do
    @sequence_class = Inferno::Sequence::USCoreR4DataAbsentReasonSequence
    @instance = Inferno::TestingInstance.create
  end

  describe 'data absent reason extension test' do
    before do
      @test = @sequence_class[:extension]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if no dar extensions have been found' do
      assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }
    end

    it 'succeeds if a dar extension has been found' do
      @instance.update!(data_absent_extension_found: true)

      @sequence.run_test(@test)
    end
  end

  describe 'data absent reason code test' do
    before do
      @test = @sequence_class[:code]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if no dar codes have been found' do
      assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }
    end

    it 'succeeds if a dar code has been found' do
      @instance.update!(data_absent_code_found: true)

      @sequence.run_test(@test)
    end
  end
end
