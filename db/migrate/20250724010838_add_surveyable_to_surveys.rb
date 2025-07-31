class AddSurveyableToSurveys < ActiveRecord::Migration[7.1]
  def change
    add_reference :survey_engine_surveys, :surveyable, polymorphic: true, null: true
    
    add_index :survey_engine_surveys, [:surveyable_type, :surveyable_id]
  end
end
