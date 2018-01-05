class LaunchSequence < SequenceBase

  description 'Demonstrate at least one Launch Sequence'
  buttonless

  test 'at least one successful launch' do
    results = @instance.latest_results
    assert (results.include?('ProviderStandaloneLaunch') && results['ProviderStandaloneLaunch'].result=='pass') ||
      (results.include?('ProviderEHRLaunch') && results['ProviderEHRLaunch'].result=='pass') ||
      (results.include?('PatientStandaloneLaunch') && results['PatientStandaloneLaunch'].result=='pass') ||
      (results.include?('PatientEHRLaunch') && results['PatientEHRLaunch'].result=='pass')
  end

end
