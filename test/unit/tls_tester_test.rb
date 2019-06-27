# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

class TlsTesterTest < MiniTest::Test
  def setup
    @tester_under_test = Inferno::TlsTester.new(uri: 'https://www.example.org/')
  end

  def test_verify_tls_1_2
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/')

    result, msg = @tester_under_test.verify_ensure_tls_v1_2
    assert result, msg
  end

  def test_deny_tls_1
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/')

    result, msg = @tester_under_test.verify_deny_tls_v1
    assert result, msg
  end

  def test_deny_tls_1_1
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/')

    result, msg = @tester_under_test.verify_deny_tls_v1_1
    assert result, msg
  end

  def test_deny_ssl_3
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/')

    result, msg = @tester_under_test.verify_deny_ssl_v3
    assert result, msg
  end

  def test_timeout
    WebMock.reset!
    stub_request(:any, 'https://www.example.org/').to_timeout

    result, msg = @tester_under_test.verify_ensure_tls_v1_2
    assert !result, msg
  end
end
