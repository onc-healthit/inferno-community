class PatientStandaloneLaunchSequence < SequenceBase

  description 'Patient Standalone Launch Sequence'
  modal_before_run
  child_test

  preconditions 'Client must be registered.' do 
    !@instance.client_id.nil?
  end

  test 'Patient Standalone Launch' do
  end
end
