class InitialDbSetup < ActiveRecord::Migration[5.2]
  def change
    create_table "inferno_models_information_messages", id: :string, limit: 50, force: :cascade do |t|
      t.string "message", limit: 500
      t.string "test_result_id", limit: 50, null: false
      t.index ["test_result_id"], name: "index_inferno_models_information_messages_test_result"
    end

    create_table "inferno_models_request_response_test_results", primary_key: ["request_response_id", "test_result_id"], force: :cascade do |t|
      t.string "request_response_id", limit: 50, null: false
      t.string "test_result_id", limit: 50, null: false
    end

    create_table "inferno_models_request_responses", id: :string, limit: 50, force: :cascade do |t|
      t.string "request_method", limit: 50
      t.string "request_url", limit: 500
      t.string "request_headers", limit: 1000
      t.text "request_payload"
      t.integer "response_code"
      t.string "response_headers", limit: 1000
      t.text "response_body"
      t.string "direction", limit: 50
      t.string "instance_id", limit: 50
      t.datetime "timestamp"
    end

    create_table "inferno_models_resource_references", id: :string, limit: 50, force: :cascade do |t|
      t.string "resource_type", limit: 50
      t.string "resource_id", limit: 50
      t.string "profile", limit: 50
      t.datetime "created_at"
      t.string "testing_instance_id", limit: 50, null: false
      t.index ["testing_instance_id"], name: "index_inferno_models_resource_references_testing_instance"
    end

    create_table "inferno_models_sequence_requirements", id: :string, limit: 50, force: :cascade do |t|
      t.string "name", limit: 50
      t.string "testing_instance_id", limit: 50
      t.string "value", limit: 50
      t.string "label", limit: 50
      t.string "description", limit: 50
      t.index ["name", "testing_instance_id"], name: "unique_inferno_models_sequence_requirements_name_by_instance", unique: true
    end

    create_table "inferno_models_sequence_results", id: :string, limit: 50, force: :cascade do |t|
      t.string "name", limit: 50
      t.string "result", limit: 50
      t.string "test_case_id", limit: 50
      t.string "test_set_id", limit: 50
      t.string "redirect_to_url", limit: 500
      t.string "wait_at_endpoint", limit: 50
      t.integer "required_passed", default: 0
      t.integer "required_total", default: 0
      t.integer "error_count", default: 0
      t.integer "todo_count", default: 0
      t.integer "skip_count", default: 0
      t.integer "optional_passed", default: 0
      t.integer "optional_total", default: 0
      t.integer "required_omitted", default: 0
      t.integer "optional_omitted", default: 0
      t.string "app_version", limit: 50
      t.boolean "required", default: true
      t.string "input_params", limit: 50
      t.string "output_results", limit: 50
      t.string "next_sequences", limit: 50
      t.string "next_test_cases", limit: 50
      t.datetime "created_at"
      t.string "testing_instance_id", limit: 50, null: false
      t.index ["testing_instance_id"], name: "index_inferno_models_sequence_results_testing_instance"
    end

    create_table "inferno_models_server_capabilities", id: :string, limit: 50, force: :cascade do |t|
      t.text "capabilities"
      t.string "testing_instance_id", limit: 50, null: false
      t.index ["testing_instance_id"], name: "index_inferno_models_server_capabilities_testing_instance"
    end

    create_table "inferno_models_test_results", id: :string, limit: 50, force: :cascade do |t|
      t.string "test_id", limit: 50
      t.string "ref", limit: 50
      t.string "name", limit: 50
      t.string "result", limit: 50
      t.string "message", limit: 500
      t.string "details", limit: 50
      t.boolean "required", default: true
      t.string "url", limit: 500
      t.text "description"
      t.integer "test_index"
      t.datetime "created_at"
      t.string "versions", limit: 50
      t.string "wait_at_endpoint", limit: 50
      t.string "redirect_to_url", limit: 50
      t.string "sequence_result_id", limit: 50, null: false
      t.index ["sequence_result_id"], name: "index_inferno_models_test_results_sequence_result"
    end

    create_table "inferno_models_test_warnings", id: :string, limit: 50, force: :cascade do |t|
      t.string "message", limit: 500
      t.string "test_result_id", limit: 50, null: false
      t.index ["test_result_id"], name: "index_inferno_models_test_warnings_test_result"
    end

    create_table "inferno_models_testing_instances", id: :string, limit: 50, force: :cascade do |t|
      t.string "url", limit: 50
      t.string "name", limit: 50
      t.boolean "confidential_client"
      t.string "client_id", limit: 50
      t.string "client_secret", limit: 50
      t.string "base_url", limit: 50
      t.string "client_name", limit: 50, default: "Inferno"
      t.string "scopes", limit: 50
      t.string "received_scopes", limit: 50
      t.string "encounter_id", limit: 50
      t.string "launch_type", limit: 50
      t.string "state", limit: 50
      t.string "selected_module", limit: 50
      t.boolean "conformance_checked"
      t.string "oauth_authorize_endpoint", limit: 50
      t.string "oauth_token_endpoint", limit: 50
      t.string "oauth_register_endpoint", limit: 50
      t.string "fhir_format", limit: 50
      t.boolean "dynamically_registered"
      t.string "client_endpoint_key", limit: 50
      t.string "token", limit: 50
      t.datetime "token_retrieved_at"
      t.integer "token_expires_in"
      t.string "id_token", limit: 50
      t.string "refresh_token", limit: 50
      t.datetime "created_at"
      t.string "oauth_introspection_endpoint", limit: 50
      t.string "resource_id", limit: 50
      t.string "resource_secret", limit: 50
      t.string "introspect_token", limit: 50
      t.string "introspect_refresh_token", limit: 50
      t.string "standalone_launch_script", limit: 50
      t.string "ehr_launch_script", limit: 50
      t.string "manual_registration_script", limit: 50
      t.string "initiate_login_uri", limit: 50
      t.string "redirect_uris", limit: 50
      t.string "dynamic_registration_token", limit: 50
      t.string "must_support_confirmed", limit: 50, default: ""
      t.string "patient_ids", limit: 50
      t.string "group_id", limit: 50
      t.string "bulk_url", limit: 50
      t.string "bulk_token_endpoint", limit: 50
      t.string "bulk_client_id", limit: 50
      t.string "bulk_system_export_endpoint", limit: 50
      t.string "bulk_patient_export_endpoint", limit: 50
      t.string "bulk_group_export_endpoint", limit: 50
      t.string "bulk_fastest_resource", limit: 50
      t.string "bulk_requires_auth", limit: 50
      t.string "bulk_since_param", limit: 50
      t.string "bulk_jwks_url_auth", limit: 50
      t.string "bulk_jwks_auth", limit: 50
      t.string "bulk_public_key", limit: 50
      t.string "bulk_private_key", limit: 50
      t.string "bulk_access_token", limit: 50
      t.string "bulk_lines_to_validate", limit: 50
      t.string "bulk_status_output", limit: 50
      t.boolean "data_absent_code_found"
      t.boolean "data_absent_extension_found"
      t.string "device_system", limit: 50
      t.string "device_code", limit: 50
      t.string "device_codes", limit: 50
      t.string "onc_sl_url", limit: 50
      t.boolean "onc_sl_confidential_client"
      t.string "onc_sl_client_id", limit: 50
      t.string "onc_sl_client_secret", limit: 50
      t.string "onc_sl_scopes", limit: 50
      t.string "onc_patient_ids", limit: 50
      t.string "bulk_encryption_method", limit: 50, default: "ES384"
      t.string "bulk_data_jwks", limit: 50
      t.string "bulk_patient_ids_in_group", limit: 50
      t.string "bulk_stop_after_must_support", limit: 50, default: "true"
      t.string "onc_sl_restricted_scopes", limit: 50
      t.string "bulk_scope", limit: 50
      t.boolean "disable_bulk_data_require_access_token_test", default: false
    end
  end
end
