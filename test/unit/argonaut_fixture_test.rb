require File.expand_path '../../test_helper.rb', __FILE__

class ArgonautFixtureTest < MiniTest::Test

  def setup
    @bundle = FHIR::DSTU2.from_contents(load_fixture('sample_record'))
    @invalid = FHIR::DSTU2.from_contents(load_fixture('sample_invalid_record'))    
  end

  def test_argonaut_fixture_validates_against_profiles
    @bundle.entry.each do |entry|
      profile = Inferno::ValidationUtil.guess_profile(entry.resource)
      unless profile.nil?
        errors = profile.validate_resource(entry.resource)
        assert errors.empty?, "#{entry.resource.resourceType} did not validate against profile: #{errors.join(", ")}"
      end
    end
  end

  def test_invalid_fixture_fails_against_profiles
    errors = []
    @invalid.entry.each do |entry|
      profile = Inferno::ValidationUtil.guess_profile(entry.resource)
      unless profile.nil?
        errors += profile.validate_resource(entry.resource)
      end
    end
    assert !errors.empty?, "Expected numerous validation errors."
  end

end
