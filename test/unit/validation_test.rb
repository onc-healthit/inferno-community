# frozen_string_literal: true

require_relative '../test_helper'

class ValidationTest < Minitest::Test
  def setup
    @diagnostic_report_lab = FHIR.from_contents(load_fixture(:us_core_r4_diagnostic_report_lab))
    @diagnostic_report_note = FHIR.from_contents(load_fixture(:us_core_r4_diagnostic_report_note))
    @lab_results = FHIR.from_contents(load_fixture(:us_core_r4_observation_lab))
    @smoking_status = FHIR.from_contents(load_fixture(:us_core_r4_smoking_status))
    @pediatric_weight_for_height = FHIR.from_contents(load_fixture(:us_core_r4_pediatric_weight_for_height))
    @pediatric_bmi_for_age = FHIR.from_contents(load_fixture(:us_core_r4_pediatric_bmi_for_age))
  end

  def test_guess_r4_profiles
    assert Inferno::ValidationUtil.guess_r4_profile(@diagnostic_report_lab).url == Inferno::ValidationUtil::US_CORE_R4_URIS[:diagnostic_report_lab]
    assert Inferno::ValidationUtil.guess_r4_profile(@diagnostic_report_note).url == Inferno::ValidationUtil::US_CORE_R4_URIS[:diagnostic_report_note]
    assert Inferno::ValidationUtil.guess_r4_profile(@lab_results).url == Inferno::ValidationUtil::US_CORE_R4_URIS[:lab_results]
    assert Inferno::ValidationUtil.guess_r4_profile(@smoking_status).url == Inferno::ValidationUtil::US_CORE_R4_URIS[:smoking_status]
    assert Inferno::ValidationUtil.guess_r4_profile(@pediatric_weight_for_height).url == Inferno::ValidationUtil::US_CORE_R4_URIS[:pediatric_weight_height]
    assert Inferno::ValidationUtil.guess_r4_profile(@pediatric_bmi_for_age).url == Inferno::ValidationUtil::US_CORE_R4_URIS[:pediatric_bmi_age]
  end
end
