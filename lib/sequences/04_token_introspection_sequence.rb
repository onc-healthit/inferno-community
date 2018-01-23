class TokenIntrospectionSequence < SequenceBase

  title 'TODO: Refresh Token'

  description 'Authorization tokens can be inspected'

  preconditions 'Client must be authorized.' do 
    !@instance.token.nil?
  end

  test 'Token introspection supported' do

    todo

  end


end
