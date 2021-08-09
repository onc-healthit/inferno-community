class AddRequestIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :inferno_models_request_response_test_results,
              :test_result_id,
              name: :index_request_response_test_results_on_test_result_id
  end
end
