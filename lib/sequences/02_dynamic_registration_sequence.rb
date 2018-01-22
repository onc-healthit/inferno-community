class DynamicRegistrationSequence < SequenceBase

  title 'Dynamic Registration'

  description 'OAuth 2.0 Dynamic Client Registration Protocol'

  modal_before_run

  preconditions 'OAuth endpoints are necessary.' do 
    !@instance.oauth_authorize_endpoint.nil? && !@instance.oauth_token_endpoint.nil?
  end

  test 'OAuth 2.0 Dynamic Client Registration Protocol' do
  end
end
