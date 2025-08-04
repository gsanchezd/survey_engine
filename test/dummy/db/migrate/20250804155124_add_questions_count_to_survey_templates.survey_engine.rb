# This migration comes from survey_engine (originally 20250801192218)
class AddQuestionsCountToSurveyTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_survey_templates, :questions_count, :integer, default: 0, null: false
  end
end
