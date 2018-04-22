
require File.expand_path '../../test_helper.rb', __FILE__

class InstancePageTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @fhir_server = "http://#{SecureRandomBase62.generate(32)}.example.com"
    post BASE_PATH, {fhir_server: @fhir_server}
    assert last_response.redirect?
    follow_redirect!
    assert last_response.ok?
    @instance_path = last_request.url
    instance_id = @instance_path.split('/').last
    @instance = TestingInstance.get(instance_id)
  end

  def instance_details_ok_test
    get @instance_path
    assert last_response.ok?
    assert last_response.body.include?(@fhir_server)
  end

  def test_not_found_instance
    get "#{BASE_PATH}/asdfasdf"
    assert last_response.not_found?
    get "#{BASE_PATH}/asdfasdf/#{@instance.client_endpoint_key}/launch"
    assert last_response.not_found?
  end

  def test_not_found_key
    get "#{@instance_path}asdfasdf/launch/"
    assert last_response.not_found?
  end

  def test_launch_sequence_not_initiated
    get "#{@instance_path}#{@instance.client_endpoint_key}/launch/"
    assert last_response.redirect?
    follow_redirect!
    assert last_request.url.include? "error=no_launch"
  end

end
