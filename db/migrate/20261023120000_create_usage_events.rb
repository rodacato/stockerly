class CreateUsageEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_events do |t| # rubocop:disable Rails/CreateTableWithTimestamps -- an event has one time, occurred_at
      t.string :name, null: false
      t.string :screen
      t.jsonb :properties, null: false, default: {}
      t.datetime :occurred_at, null: false
    end
    add_index :usage_events, %i[name occurred_at]
    add_index :usage_events, :occurred_at
  end
end
