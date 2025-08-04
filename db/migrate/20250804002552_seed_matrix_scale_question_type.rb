class SeedMatrixScaleQuestionType < ActiveRecord::Migration[8.0]
  def up
    SurveyEngine::QuestionType.find_or_create_by(name: 'matrix_scale') do |qt|
      qt.allows_options = true
      qt.allows_multiple_selections = false
    end
  end

  def down
    SurveyEngine::QuestionType.where(name: 'matrix_scale').destroy_all
  end
end
