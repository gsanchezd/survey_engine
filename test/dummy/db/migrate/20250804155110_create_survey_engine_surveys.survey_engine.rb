# This migration comes from survey_engine (originally 20250721034001)
class CreateSurveyEngineSurveys < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_engine_surveys do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :is_active, null: false, default: false
      t.boolean :global, null: false, default: false
      t.datetime :published_at
      t.datetime :expires_at
      t.string :status, null: false, default: 'draft'

      t.timestamps null: false
    end

    add_index :survey_engine_surveys, :status
    add_index :survey_engine_surveys, :is_active
    add_index :survey_engine_surveys, [:global, :is_active]
  end
end
