class SeedRankingQuestionType < ActiveRecord::Migration[7.1]
  def up
    SurveyEngine::QuestionType.find_or_create_by(name: "ranking") do |qt|
      qt.description = "Ordenar elementos por prioridad"
      qt.allows_options = true
      qt.allows_multiple_selections = true
    end
  end

  def down
    SurveyEngine::QuestionType.where(name: "ranking").destroy_all
  end
end
