class ProviderEHRLaunchSequence < SequenceBase

  description 'Provider EHR Launch Sequence'
  modal_before_run
  child_test

  preconditions 'Client must be registered.' do 
    !@instance.client_id.nil?
  end

  test 'Provider EHR Launch' do
  end
end
