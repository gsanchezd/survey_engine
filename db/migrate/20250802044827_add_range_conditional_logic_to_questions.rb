class AddRangeConditionalLogicToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_questions, :conditional_operator_2, :string
    add_column :survey_engine_questions, :conditional_value_2, :decimal
    add_column :survey_engine_questions, :conditional_logic_type, :string, default: 'single'

    # Add index for performance on the new logic type field
    add_index :survey_engine_questions, :conditional_logic_type
  end
end
