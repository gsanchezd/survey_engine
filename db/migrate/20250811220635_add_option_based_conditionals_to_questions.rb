class AddOptionBasedConditionalsToQuestions < ActiveRecord::Migration[7.1]
  def up
    # Add field to specify the conditional type (scale vs option)
    add_column :survey_engine_questions, :conditional_type, :string, default: 'scale'
    add_index :survey_engine_questions, :conditional_type

    # Create join table for option-based conditionals
    create_table :survey_engine_question_conditional_options do |t|
      t.references :question, null: false, foreign_key: { to_table: :survey_engine_questions }
      t.references :option, null: false, foreign_key: { to_table: :survey_engine_options }
      t.timestamps
    end

    # Add unique index to prevent duplicate entries
    add_index :survey_engine_question_conditional_options, [ :question_id, :option_id ],
              unique: true, name: 'index_question_conditional_options_unique'
  end

  def down
    drop_table :survey_engine_question_conditional_options
    remove_index :survey_engine_questions, :conditional_type
    remove_column :survey_engine_questions, :conditional_type
  end
end
