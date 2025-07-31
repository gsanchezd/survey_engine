class CreateSurveyEngineOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_engine_options do |t|
      t.references :question, null: false, foreign_key: { to_table: :survey_engine_questions }
      t.string :option_text, null: false
      t.string :option_value, null: false
      t.integer :order_position, null: false
      t.boolean :is_other, null: false, default: false
      t.boolean :is_exclusive, null: false, default: false
      t.boolean :is_active, null: false, default: true
      t.text :skip_logic

      t.timestamps null: false
    end

    add_index :survey_engine_options, [:question_id, :order_position], unique: true
    add_index :survey_engine_options, [:question_id, :is_active]
  end
end
