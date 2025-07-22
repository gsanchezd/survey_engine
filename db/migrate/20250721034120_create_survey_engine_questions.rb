class CreateSurveyEngineQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :survey_engine_questions do |t|
      t.references :survey, null: false, foreign_key: { to_table: :survey_engine_surveys }
      t.references :question_type, null: false, foreign_key: { to_table: :survey_engine_question_types }
      t.string :title, null: false
      t.text :description
      t.boolean :is_required, null: false, default: false
      t.integer :order_position, null: false
      t.integer :scale_min
      t.integer :scale_max
      t.string :scale_min_label
      t.string :scale_max_label
      t.integer :max_characters
      t.integer :min_selections
      t.integer :max_selections
      t.boolean :allow_other, null: false, default: false
      t.boolean :randomize_options, null: false, default: false
      t.text :validation_rules
      t.string :placeholder_text
      t.text :help_text

      t.timestamps null: false
    end

    add_index :survey_engine_questions, [:survey_id, :order_position], unique: true
  end
end
