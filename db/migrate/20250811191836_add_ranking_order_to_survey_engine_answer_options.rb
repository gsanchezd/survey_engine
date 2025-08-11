class AddRankingOrderToSurveyEngineAnswerOptions < ActiveRecord::Migration[8.0]
  def change
    add_column :survey_engine_answer_options, :ranking_order, :integer
  end
end
