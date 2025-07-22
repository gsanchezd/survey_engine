class CreateSurveyEngineResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :survey_engine_responses do |t|
      t.references :survey, null: false, foreign_key: { to_table: :survey_engine_surveys }
      t.references :participant, null: false, foreign_key: { to_table: :survey_engine_participants }
      t.datetime :completed_at

      t.timestamps
    end

    add_index :survey_engine_responses, :completed_at
  end
end
