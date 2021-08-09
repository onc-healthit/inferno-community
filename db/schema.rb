# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_08_04_135524) do

  create_table "inferno_models_information_messages", id: :string, limit: 500, force: :cascade do |t|
    t.text "message"
    t.string "test_result_id", limit: 500, null: false
    t.index ["test_result_id"], name: "index_inferno_models_information_messages_test_result"
  end

  create_table "inferno_models_request_response_test_results", primary_key: ["request_response_id", "test_result_id"], force: :cascade do |t|
    t.string "request_response_id", limit: 500, null: false
    t.string "test_result_id", limit: 500, null: false
    t.index ["test_result_id"], name: "index_request_response_test_results_on_test_result_id"
  end

  create_table "inferno_models_request_responses", id: :string, limit: 500, force: :cascade do |t|
    t.string "request_method", limit: 500
    t.text "request_url"
    t.text "request_headers"
    t.text "request_payload"
    t.integer "response_code"
    t.text "response_headers"
    t.text "response_body"
    t.string "direction", limit: 500
    t.string "instance_id", limit: 500
    t.datetime "timestamp"
    t.index ["instance_id"], name: "index_request_responses_on_instance_id"
  end

  create_table "inferno_models_resource_references", id: :string, limit: 500, force: :cascade do |t|
    t.string "resource_type", limit: 500
    t.string "resource_id", limit: 500
    t.string "profile", limit: 500
    t.datetime "created_at"
    t.string "testing_instance_id", limit: 500, null: false
    t.index ["testing_instance_id", "profile"], name: "index_resource_references_on_instance_id_and_profile"
    t.index ["testing_instance_id", "resource_type"], name: "index_resource_references_on_instance_id_and_resource_type"
    t.index ["testing_instance_id"], name: "index_inferno_models_resource_references_testing_instance"
    t.index ["testing_instance_id"], name: "index_resource_references_on_instance_id"
  end

  create_table "inferno_models_sequence_requirements", id: :string, limit: 500, force: :cascade do |t|
    t.string "name", limit: 500
    t.string "testing_instance_id", limit: 500
    t.text "value"
    t.string "label", limit: 500
    t.text "description"
    t.index ["name", "testing_instance_id"], name: "unique_inferno_models_sequence_requirements_name_by_instance", unique: true
  end

  create_table "inferno_models_sequence_results", id: :string, limit: 500, force: :cascade do |t|
    t.string "name", limit: 500
    t.string "result", limit: 500
    t.text "test_case_id"
    t.text "test_set_id"
    t.text "redirect_to_url"
    t.text "wait_at_endpoint"
    t.integer "required_passed", default: 0
    t.integer "required_total", default: 0
    t.integer "error_count", default: 0
    t.integer "todo_count", default: 0
    t.integer "skip_count", default: 0
    t.integer "optional_passed", default: 0
    t.integer "optional_total", default: 0
    t.integer "required_omitted", default: 0
    t.integer "optional_omitted", default: 0
    t.string "app_version", limit: 500
    t.boolean "required", default: true
    t.text "input_params"
    t.text "output_results"
    t.text "next_sequences"
    t.text "next_test_cases"
    t.datetime "created_at"
    t.string "testing_instance_id", limit: 500, null: false
    t.boolean "expect_redirect_failure", default: false
    t.index ["testing_instance_id"], name: "index_inferno_models_sequence_results_testing_instance"
  end

  create_table "inferno_models_server_capabilities", id: :string, limit: 50, force: :cascade do |t|
    t.text "capabilities"
    t.string "testing_instance_id", limit: 500, null: false
    t.index ["testing_instance_id"], name: "index_inferno_models_server_capabilities_testing_instance"
  end

  create_table "inferno_models_test_results", id: :string, limit: 500, force: :cascade do |t|
    t.string "test_id", limit: 500
    t.text "ref"
    t.text "name"
    t.string "result", limit: 500
    t.text "message"
    t.text "details"
    t.boolean "required", default: true
    t.text "url"
    t.text "description"
    t.integer "test_index"
    t.datetime "created_at"
    t.string "versions", limit: 500
    t.text "wait_at_endpoint"
    t.text "redirect_to_url"
    t.string "sequence_result_id", limit: 500, null: false
    t.boolean "expect_redirect_failure", default: false
    t.index ["sequence_result_id"], name: "index_inferno_models_test_results_sequence_result"
  end

  create_table "inferno_models_test_warnings", id: :string, limit: 500, force: :cascade do |t|
    t.text "message"
    t.string "test_result_id", limit: 500, null: false
    t.index ["test_result_id"], name: "index_inferno_models_test_warnings_test_result"
  end

  create_table "inferno_models_testing_instances", id: :string, limit: 500, force: :cascade do |t|
    t.text "url"
    t.string "name", limit: 50
    t.boolean "confidential_client"
    t.text "client_id"
    t.text "client_secret"
    t.text "base_url"
    t.string "client_name", limit: 50, default: "Inferno"
    t.text "scopes"
    t.text "received_scopes"
    t.string "encounter_id", limit: 50
    t.string "launch_type", limit: 50
    t.text "state"
    t.string "selected_module", limit: 50
    t.boolean "conformance_checked"
    t.text "oauth_authorize_endpoint"
    t.text "oauth_token_endpoint"
    t.text "oauth_register_endpoint"
    t.string "fhir_format", limit: 50
    t.boolean "dynamically_registered"
    t.string "client_endpoint_key", limit: 50
    t.text "token"
    t.datetime "token_retrieved_at"
    t.integer "token_expires_in"
    t.text "id_token"
    t.text "refresh_token"
    t.datetime "created_at"
    t.text "oauth_introspection_endpoint"
    t.text "resource_id"
    t.text "resource_secret"
    t.text "introspect_token"
    t.text "introspect_refresh_token"
    t.text "standalone_launch_script"
    t.text "ehr_launch_script"
    t.text "manual_registration_script"
    t.text "initiate_login_uri"
    t.text "redirect_uris"
    t.text "dynamic_registration_token"
    t.string "must_support_confirmed", limit: 50, default: ""
    t.text "patient_ids"
    t.text "group_id"
    t.text "bulk_url"
    t.text "bulk_token_endpoint"
    t.text "bulk_client_id"
    t.text "bulk_system_export_endpoint"
    t.text "bulk_patient_export_endpoint"
    t.text "bulk_group_export_endpoint"
    t.text "bulk_fastest_resource"
    t.string "bulk_requires_auth", limit: 50
    t.string "bulk_since_param", limit: 50
    t.text "bulk_jwks_url_auth"
    t.text "bulk_jwks_auth"
    t.text "bulk_public_key"
    t.text "bulk_private_key"
    t.text "bulk_access_token"
    t.text "bulk_lines_to_validate"
    t.text "bulk_status_output"
    t.boolean "data_absent_code_found"
    t.boolean "data_absent_extension_found"
    t.string "device_system", limit: 50
    t.string "device_code", limit: 50
    t.string "device_codes", limit: 50
    t.text "onc_sl_url"
    t.boolean "onc_sl_confidential_client"
    t.text "onc_sl_client_id"
    t.text "onc_sl_client_secret"
    t.text "onc_sl_scopes"
    t.text "onc_patient_ids"
    t.string "bulk_encryption_method", limit: 50, default: "ES384"
    t.text "bulk_data_jwks"
    t.text "bulk_patient_ids_in_group"
    t.string "bulk_stop_after_must_support", limit: 50, default: "true"
    t.text "onc_sl_restricted_scopes"
    t.text "bulk_scope"
    t.boolean "disable_bulk_data_require_access_token_test", default: false
  end

end
