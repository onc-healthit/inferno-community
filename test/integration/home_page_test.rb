require File.expand_path '../../test_helper.rb', __FILE__
class HomePageTest < MiniTest::Unit::TestCase

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

end
