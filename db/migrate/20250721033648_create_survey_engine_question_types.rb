class CreateSurveyEngineQuestionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :survey_engine_question_types do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :allows_options, null: false, default: false
      t.boolean :allows_multiple_selections, null: false, default: false

      t.timestamps null: false
    end

    add_index :survey_engine_question_types, :name, unique: true
  end
end
