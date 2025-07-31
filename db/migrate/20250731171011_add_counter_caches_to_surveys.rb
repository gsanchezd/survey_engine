class AddCounterCachesToSurveys < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_surveys, :questions_count, :integer, default: 0, null: false
    add_column :survey_engine_surveys, :participants_count, :integer, default: 0, null: false
    
    # Reset counter caches for existing surveys
    reversible do |dir|
      dir.up do
        SurveyEngine::Survey.find_each do |survey|
          SurveyEngine::Survey.reset_counters(survey.id, :questions, :participants)
        end
      end
    end
  end
end
