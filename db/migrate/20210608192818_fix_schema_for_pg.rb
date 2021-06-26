class FixSchemaForPg < ActiveRecord::Migration[5.2]
  def change
    change_column 'inferno_models_information_messages', :message, :text, limit: nil
    change_column 'inferno_models_information_messages', :id, :string, limit: 500
    change_column 'inferno_models_information_messages', :test_result_id, :string, limit: 500

    change_column 'inferno_models_request_response_test_results', :request_response_id, :string, limit: 500
    change_column 'inferno_models_request_response_test_results', :test_result_id, :string, limit: 500

    change_column 'inferno_models_request_responses', :request_url, :text, limit: nil
    change_column 'inferno_models_request_responses', :request_headers, :text, limit: nil
    change_column 'inferno_models_request_responses', :response_headers, :text, limit: nil
    change_column 'inferno_models_request_responses', :id, :string, limit: 500
    change_column 'inferno_models_request_responses', :request_method, :string, limit: 500
    change_column 'inferno_models_request_responses', :direction, :string, limit: 500
    change_column 'inferno_models_request_responses', :instance_id, :string, limit: 500
    add_index 'inferno_models_request_responses', :instance_id, name: 'index_request_responses_on_instance_id'

    change_column 'inferno_models_resource_references', :resource_type, :string, limit: 500
    change_column 'inferno_models_resource_references', :resource_id, :string, limit: 500
    change_column 'inferno_models_resource_references', :id, :string, limit: 500
    change_column 'inferno_models_resource_references', :testing_instance_id, :string, limit: 500
    change_column 'inferno_models_resource_references', :profile, :string, limit: 500
    add_index 'inferno_models_resource_references', :testing_instance_id, name: 'index_resource_references_on_instance_id'
    add_index 'inferno_models_resource_references', [:testing_instance_id, :resource_type], name: 'index_resource_references_on_instance_id_and_resource_type'
    add_index 'inferno_models_resource_references', [:testing_instance_id, :profile], name: 'index_resource_references_on_instance_id_and_profile'

    change_column 'inferno_models_sequence_requirements', :id, :string, limit: 500
    change_column 'inferno_models_sequence_requirements', :name, :string, limit: 500
    change_column 'inferno_models_sequence_requirements', :testing_instance_id, :string, limit: 500
    change_column 'inferno_models_sequence_requirements', :label, :string, limit: 500
    change_column 'inferno_models_sequence_requirements', :value, :text, limit: nil
    change_column 'inferno_models_sequence_requirements', :description, :text, limit: nil

    change_column 'inferno_models_sequence_results', :test_case_id, :text, limit: nil
    change_column 'inferno_models_sequence_results', :test_set_id, :text, limit: nil
    change_column 'inferno_models_sequence_results', :redirect_to_url, :text, limit: nil
    change_column 'inferno_models_sequence_results', :wait_at_endpoint, :text, limit: nil
    change_column 'inferno_models_sequence_results', :app_version, :string, limit: 500
    change_column 'inferno_models_sequence_results', :input_params, :text, limit: nil
    change_column 'inferno_models_sequence_results', :output_results, :text, limit: nil
    change_column 'inferno_models_sequence_results', :next_sequences, :text, limit: nil
    change_column 'inferno_models_sequence_results', :next_test_cases, :text, limit: nil
    change_column 'inferno_models_sequence_results', :id, :string, limit: 500
    change_column 'inferno_models_sequence_results', :name, :string, limit: 500
    change_column 'inferno_models_sequence_results', :result, :string, limit: 500
    change_column 'inferno_models_sequence_results', :testing_instance_id, :string, limit: 500

    change_column 'inferno_models_server_capabilities', :testing_instance_id, :string, limit: 500

    change_column 'inferno_models_test_results', :ref, :text, limit: nil
    change_column 'inferno_models_test_results', :name, :text, limit: nil
    change_column 'inferno_models_test_results', :message, :text, limit: nil
    change_column 'inferno_models_test_results', :details, :text, limit: nil
    change_column 'inferno_models_test_results', :url, :text, limit: nil
    change_column 'inferno_models_test_results', :versions, :string, limit: 500
    change_column 'inferno_models_test_results', :wait_at_endpoint, :text, limit: nil
    change_column 'inferno_models_test_results', :redirect_to_url, :text, limit: nil
    change_column 'inferno_models_test_results', :id, :string, limit: 500
    change_column 'inferno_models_test_results', :result, :string, limit: 500
    change_column 'inferno_models_test_results', :test_id, :string, limit: 500
    change_column 'inferno_models_test_results', :sequence_result_id, :string, limit: 500

    change_column 'inferno_models_test_warnings', :message, :text, limit: nil
    change_column 'inferno_models_test_warnings', :id, :string, limit: 500
    change_column 'inferno_models_test_warnings', :test_result_id, :string, limit: 500

    change_column 'inferno_models_testing_instances', :id, :string, limit: 500
    change_column 'inferno_models_testing_instances', :url, :text, limit: nil
    change_column 'inferno_models_testing_instances', :client_id, :text, limit: nil
    change_column 'inferno_models_testing_instances', :client_secret, :text, limit: nil
    change_column 'inferno_models_testing_instances', :base_url, :text, limit: nil
    change_column 'inferno_models_testing_instances', :scopes, :text, limit: nil
    change_column 'inferno_models_testing_instances', :received_scopes, :text, limit: nil
    change_column 'inferno_models_testing_instances', :state, :text, limit: nil
    # encounter_id
    change_column 'inferno_models_testing_instances', :oauth_authorize_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :oauth_token_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :oauth_register_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :id_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :refresh_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :oauth_introspection_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :resource_id, :text, limit: nil
    change_column 'inferno_models_testing_instances', :resource_secret, :text, limit: nil
    change_column 'inferno_models_testing_instances', :introspect_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :introspect_refresh_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :standalone_launch_script, :text, limit: nil
    change_column 'inferno_models_testing_instances', :ehr_launch_script, :text, limit: nil
    change_column 'inferno_models_testing_instances', :manual_registration_script, :text, limit: nil
    change_column 'inferno_models_testing_instances', :initiate_login_uri, :text, limit: nil
    change_column 'inferno_models_testing_instances', :redirect_uris, :text, limit: nil
    change_column 'inferno_models_testing_instances', :dynamic_registration_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :patient_ids, :text, limit: nil
    change_column 'inferno_models_testing_instances', :group_id, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_url, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_token_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_client_id, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_system_export_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_patient_export_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_group_export_endpoint, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_fastest_resource, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_jwks_url_auth, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_jwks_auth, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_data_jwks, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_access_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_status_output, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_patient_ids_in_group, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_scope, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_public_key, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_private_key, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_access_token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :bulk_lines_to_validate, :text, limit: nil
    change_column 'inferno_models_testing_instances', :onc_sl_url, :text, limit: nil
    change_column 'inferno_models_testing_instances', :onc_sl_client_id, :text, limit: nil
    change_column 'inferno_models_testing_instances', :onc_sl_client_secret, :text, limit: nil
    change_column 'inferno_models_testing_instances', :onc_sl_scopes, :text, limit: nil
    change_column 'inferno_models_testing_instances', :onc_patient_ids, :text, limit: nil
    change_column 'inferno_models_testing_instances', :onc_sl_restricted_scopes, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
    change_column 'inferno_models_testing_instances', :token, :text, limit: nil
  end
end
