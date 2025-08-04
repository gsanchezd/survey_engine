class SeedTextareaQuestionType < ActiveRecord::Migration[8.0]
  def up
    SurveyEngine::QuestionType.find_or_create_by(name: 'textarea') do |qt|
      qt.description = 'Long text input'
      qt.allows_options = false
      qt.allows_multiple_selections = false
    end
  end

  def down
    SurveyEngine::QuestionType.where(name: 'textarea').destroy_all
  end
end
