class CreateUserActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :user_activities do |t|
      t.references :user,        null: false, foreign_key: true, index: true
      t.string     :action,      null: false
      t.jsonb      :params,      null: false, default: {}
      t.datetime   :occurred_at, null: false

      t.timestamps
    end

    add_index :user_activities, :action
    add_index :user_activities, :occurred_at
    add_index :user_activities, [ :user_id, :action, :occurred_at ],
              name: "index_user_activities_on_user_action_occurred"
  end
end
