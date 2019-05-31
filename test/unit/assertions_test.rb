# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

class AssertionsTest < MiniTest::Test
  def setup
    # Create an instance of an anonymous class to wrap Inferno's assertions which collide/conflct with the tests methods
    @inferno_asserter = Class.new do
      include Inferno::Assertions
    end.new
  end

  def test_assert_tls_1_2
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/')

    result, msg = @inferno_asserter.assert_tls_1_2('https://www.example.org/')
    result = true if result.nil?
    assert result, msg
  end

  def test_assert_deny_previous_tls
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/')

    result, msg = @inferno_asserter.assert_deny_previous_tls('https://www.example.org/')
    result = true if result.nil?
    assert result, msg
  end
end
