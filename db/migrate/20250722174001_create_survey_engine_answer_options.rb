class CreateSurveyEngineAnswerOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_engine_answer_options do |t|
      t.references :answer, null: false, foreign_key: { to_table: :survey_engine_answers }
      t.references :option, null: false, foreign_key: { to_table: :survey_engine_options }

      t.timestamps
    end

    add_index :survey_engine_answer_options, [:answer_id, :option_id], unique: true, name: 'index_answer_options_on_answer_option'
  end
end
