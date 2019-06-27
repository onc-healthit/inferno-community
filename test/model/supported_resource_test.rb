# frozen_string_literal: true

require_relative '../test_helper'

class SupportedResourceTest < MiniTest::Test
  def setup
    resource1 = {
      attributes: {
        resource_type: 'Patient',
        index: 1,
        testing_instance_id: 1,
        supported: true,
        read_supported: true,
        vread_supported: true,
        search_supported: true,
        history_supported: true,
        scope_supported: true
      },
      description: 'supported and supports all operations',
      expected_respones: {
        validate_supported_interactions:
            %i[read vread search history authorized]
      }
    }

    resource2 = resource1.deep_dup
    resource2[:attributes][:supported] = false
    resource2[:description] = 'not supported, but supports all operations'
    resource2[:expected_respones][:validate_supported_interactions] = nil

    resource3 = resource1.deep_dup
    resource3[:attributes][:vread_supported] = false
    resource3[:description] = 'supported and supports all operations except vread'
    resource3[:expected_respones][:validate_supported_interactions] = %i[read search history authorized]

    @supported_test_cases = [resource1, resource3]
    @supported_test_cases.each do |test_case|
      test_case[:instance] = Inferno::Models::SupportedResource.create(test_case[:attributes])
    end

    @unsupported_test_cases = [resource2]
    @unsupported_test_cases.each do |test_case|
      test_case[:instance] = Inferno::Models::SupportedResource.create(test_case[:attributes])
    end
  end

  def validate_supported_interactions(resource_to_test, expected_response)
    assert_equal expected_response, resource_to_test.supported_interactions
  end

  def validate_unsupported_interactions(resource_to_test, expected_response)
    assert_nil expected_response
    assert_nil resource_to_test.supported_interactions
  end

  def test_supported_interactions_all_pass
    @supported_test_cases.each do |test_case|
      validate_supported_interactions(test_case[:instance],
                                      test_case[:expected_respones][:validate_supported_interactions])
    end
  end

  def test_unsupported_interactions_all_pass
    @unsupported_test_cases.each do |test_case|
      validate_unsupported_interactions(test_case[:instance],
                                      test_case[:expected_respones][:validate_supported_interactions])
    end
  end
end
