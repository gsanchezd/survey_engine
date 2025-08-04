# This migration comes from survey_engine (originally 20250722173131)
class CreateSurveyEngineParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_engine_participants do |t|
      t.references :survey, null: false, foreign_key: { to_table: :survey_engine_surveys }
      t.string :email, null: false
      t.string :status, null: false, default: 'invited'
      t.datetime :completed_at

      t.timestamps
    end

    add_index :survey_engine_participants, [:survey_id, :email], unique: true, name: 'index_participants_on_survey_email'
    add_index :survey_engine_participants, :status
  end
end