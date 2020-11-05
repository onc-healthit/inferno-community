class AddExpectRedirectFailure < ActiveRecord::Migration[5.2]
  def change
    add_column :inferno_models_test_results, :expect_redirect_failure, :boolean, default: false
    add_column :inferno_models_sequence_results, :expect_redirect_failure, :boolean, default: false
  end
end
