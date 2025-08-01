class AddQuestionsCountToSurveyTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :survey_engine_survey_templates, :questions_count, :integer, default: 0, null: false
  end
end
