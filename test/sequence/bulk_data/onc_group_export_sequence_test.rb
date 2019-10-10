# frozen_string_literal: true

require_relative '../../test_helper'

class OncBulkDataGroupExportSequenceTest < MiniTest::Test
  def setup
    @instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'bulk_data',
      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
      scopes: 'launch openid patient/*.* profile',
      token: 99_897_979
    )

    @instance.save!
    client = FHIR::Client.new(@instance.url)
    client.use_stu3
    client.default_json

    @sequence = Inferno::Sequence::OncBulkDataGroupExportSequence.new(@instance, client, true)

    @expected_output = @sequence.required_resources.map{|type| {'type' => type}}
  end

  def test_check_output_type_pass_with_required_types
    assert @sequence.check_output_type(@expected_output)
  end

  def test_check_output_type_fail_with_missing_type
    actual_output = @expected_output.clone
    actual_output.pop

    assert_raises Inferno::SkipException do
      @sequence.check_output_type(actual_output)
    end
  end

end