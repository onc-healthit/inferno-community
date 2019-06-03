# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

class LoggedRestClientTest < MiniTest::Test
  def test_loggedrestclient_get_ok
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:get, url)
      .to_return(status: 200)

    response = Inferno::LoggedRestClient.get(url)
    assert response.code == 200
  end

  def test_loggedrestclient_get_created
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:get, url)
      .to_return(status: 201)

    response = Inferno::LoggedRestClient.get(url)
    assert response.code == 201
  end

  def test_loggedrestclient_get_not_found
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:get, url)
      .to_return(status: 404)

    response = Inferno::LoggedRestClient.get(url)
    assert response.code == 404
  end

  def test_loggedrestclient_get_bad
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:get, url)
      .to_return(status: 400)

    response = Inferno::LoggedRestClient.get(url)
    assert response.code == 400
  end

  def test_loggedrestclient_post_ok
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:post, url)
      .to_return(status: 200)

    response = Inferno::LoggedRestClient.post(url, nil)
    assert response.code == 200
  end

  def test_loggedrestclient_post_created
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:post, url)
      .to_return(status: 201)

    response = Inferno::LoggedRestClient.post(url, nil)
    assert response.code == 201
  end

  def test_loggedrestclient_post_not_found
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:post, url)
      .to_return(status: 404)

    response = Inferno::LoggedRestClient.post(url, nil)
    assert response.code == 404
  end

  def test_loggedrestclient_post_bad
    WebMock.reset!
    url = 'http://www.example.com/stuff'

    stub_request(:post, url)
      .to_return(status: 400)

    response = Inferno::LoggedRestClient.post(url, nil)
    assert response.code == 400
  end
end
