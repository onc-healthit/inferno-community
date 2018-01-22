class LaunchSequence < SequenceBase

  title 'Demonstrate at least one Launch Sequence'
  description 'Demonstrate at least one Launch Sequence'
  buttonless

  test 'at least one successful launch' do
    results = @instance.latest_results
    assert (results.include?('ProviderEHRLaunch') && results['ProviderEHRLaunch'].result=='pass') ||
      (results.include?('PatientStandaloneLaunch') && results['PatientStandaloneLaunch'].result=='pass')
  end
end
