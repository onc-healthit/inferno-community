# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
class HomePageTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Inferno::App.new
  end

  def test_front_page_responds
    get '/'
    assert last_response.ok?
    assert last_response.body.downcase.include? 'html'
  end

  def test_404_page
    get '/asdfasdf'
    assert last_response.not_found?
  end

  def test_static_files
    get '/inferno/static/js/app.js'
    assert last_response.ok?
  end

  def test_disallow_static_path_traversal
    get '/inferno/static/../lib/version.rb'
    assert last_response.not_found?, 'Static file path traversal allowed.'

    get '/inferno/static/%2e%2e%2flib/version.rb'
    assert last_response.not_found?, 'Single encoding path traversal allowed.'

    get '/inferno/static/%252e%252e%252flib/version.rb'
    assert last_response.not_found?, 'Double encoding path traversal allowed.'

    get '/inferno/static/%25252e%25252e%25252flib/version.rb'
    assert last_response.not_found?, 'Triple encoding path traversal allowed.'
  end
end
