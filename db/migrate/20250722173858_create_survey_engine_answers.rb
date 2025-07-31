class CreateSurveyEngineAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_engine_answers do |t|
      t.references :response, null: false, foreign_key: { to_table: :survey_engine_responses }
      t.references :question, null: false, foreign_key: { to_table: :survey_engine_questions }
      t.text :text_answer
      t.integer :numeric_answer
      t.decimal :decimal_answer, precision: 10, scale: 2
      t.boolean :boolean_answer
      t.text :other_text
      t.integer :selection_count, default: 0
      t.datetime :answered_at

      t.timestamps
    end

    add_index :survey_engine_answers, [:response_id, :question_id], unique: true, name: 'index_answers_on_response_question'
    add_index :survey_engine_answers, :answered_at
  end
end
