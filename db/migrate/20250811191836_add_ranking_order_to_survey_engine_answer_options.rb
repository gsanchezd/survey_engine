class AddRankingOrderToSurveyEngineAnswerOptions < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_answer_options, :ranking_order, :integer
  end
end
