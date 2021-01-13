# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

describe Inferno::AssertionException do
  describe '#update_result' do
    it 'fails the test and sets message and details' do
      message = 'MESSAGE'
      details = 'DETAILS'
      result = Inferno::TestResult.new

      Inferno::AssertionException.new(message, details).update_result(result)

      assert result.fail?
      assert result.message == message
      assert result.details == details
    end
  end
end

describe Inferno::SkipException do
  describe '#update_result' do
    it 'skips the test and sets message and details' do
      message = 'MESSAGE'
      details = 'DETAILS'
      result = Inferno::TestResult.new

      Inferno::SkipException.new(message, details).update_result(result)

      assert result.skip?
      assert result.message == message
      assert result.details == details
    end
  end
end

describe Inferno::TodoException do
  describe '#update_result' do
    it 'todos the test and sets message' do
      message = 'MESSAGE'
      result = Inferno::TestResult.new

      Inferno::TodoException.new(message).update_result(result)

      assert result.todo?
      assert result.message == message
    end
  end
end

describe Inferno::PassException do
  describe '#update_result' do
    it 'passes the test and sets message' do
      message = 'MESSAGE'
      result = Inferno::TestResult.new

      Inferno::PassException.new(message).update_result(result)

      assert result.pass?
      assert result.message == message
    end
  end
end

describe Inferno::OmitException do
  describe '#update_result' do
    it 'omits the test and sets message' do
      message = 'MESSAGE'
      result = Inferno::TestResult.new

      Inferno::OmitException.new(message).update_result(result)

      assert result.omit?
      assert result.message == message
    end
  end
end

describe Inferno::WaitException do
  describe '#update_result' do
    it 'waits and sets endpoint' do
      endpoint = 'ENDPOINT'
      result = Inferno::TestResult.new

      Inferno::WaitException.new(endpoint).update_result(result)

      assert result.wait?
      assert result.wait_at_endpoint == endpoint
    end
  end
end

describe Inferno::RedirectException do
  describe '#update_result' do
    it 'waits and sets endpoint and redirection url' do
      endpoint = 'ENDPOINT'
      url = 'URL'
      result = Inferno::TestResult.new

      Inferno::RedirectException.new(url, endpoint).update_result(result)

      assert result.wait?
      assert result.wait_at_endpoint == endpoint
      assert result.redirect_to_url == url
    end
  end
end

describe ClientException do
  describe '#update_result' do
    it 'fails the test and sets message' do
      message = 'MESSAGE'
      result = Inferno::TestResult.new

      ClientException.new(message).update_result(result)

      assert result.fail?
      assert result.message == message
    end
  end
end
