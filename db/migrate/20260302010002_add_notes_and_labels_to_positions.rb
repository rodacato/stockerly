class AddNotesAndLabelsToPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :positions, :notes, :text
    add_column :positions, :labels, :string, array: true, default: []
  end
end
