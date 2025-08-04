# This migration comes from survey_engine (originally 20250724191603)
class AddConditionalFlowToQuestions < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_questions, :conditional_parent_id, :integer
    add_column :survey_engine_questions, :conditional_operator, :string
    add_column :survey_engine_questions, :conditional_value, :decimal
    add_column :survey_engine_questions, :show_if_condition_met, :boolean, default: true
    
    add_foreign_key :survey_engine_questions, :survey_engine_questions, column: :conditional_parent_id
    add_index :survey_engine_questions, :conditional_parent_id
  end
end
