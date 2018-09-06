require File.expand_path '../../test_helper.rb', __FILE__

class TlsTesterTest < MiniTest::Unit::TestCase

  def setup
    @tester_under_test = TlsTester.new({uri: 'https://www.example.org/'})
  end

  def test_verify_tls_1_2
    WebMock.reset!
    stub_request(:any, "https://www.example.org/")

    result, msg =@tester_under_test.verifyEnsureTLSv1_2
    assert result, msg
  end

  def test_deny_tls_1
    WebMock.reset!
    stub_request(:any, "https://www.example.org/")

    result, msg =@tester_under_test.verifyDenyTLSv1
    assert result
  end

  def test_deny_tls_1_1
    WebMock.reset!
    stub_request(:any, "https://www.example.org/")

    result, msg =@tester_under_test.verifyDenyTLSv1_1
    assert result
  end

  def test_deny_ssl_3
    WebMock.reset!
    stub_request(:any, "https://www.example.org/")

    result, msg =@tester_under_test.verifyDenySSLv3
    assert result
  end

  def test_timeout
    WebMock.reset!
    stub_request(:any, "https://www.example.org/").to_timeout

    result, msg = @tester_under_test.verifyEnsureTLSv1_2
    assert !result
  end
end
