# This migration comes from survey_engine (originally 20250724010838)
class AddSurveyableToSurveys < ActiveRecord::Migration[7.1]
  def change
    add_reference :survey_engine_surveys, :surveyable, polymorphic: true, null: true, index: false
    
    add_index :survey_engine_surveys, [:surveyable_type, :surveyable_id], 
              name: 'index_survey_engine_surveys_on_surveyable'
  end
end
