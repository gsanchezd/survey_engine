class AddQuestionsCountToSurveyTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_survey_templates, :questions_count, :integer, default: 0, null: false
  end
end
