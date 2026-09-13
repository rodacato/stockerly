class RemoveConsentsDataProcessingAtFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :consents_data_processing_at, :datetime
  end
end
