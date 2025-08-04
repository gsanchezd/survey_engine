# This migration comes from survey_engine (originally 20250801839121)
class AddMatrixSupportToQuestions < ActiveRecord::Migration[7.1]
  def change
    # Add matrix support fields to questions
    add_reference :survey_engine_questions, :matrix_parent, null: true, foreign_key: { to_table: :survey_engine_questions }
    add_column :survey_engine_questions, :is_matrix_question, :boolean, default: false, null: false
    add_column :survey_engine_questions, :matrix_row_text, :string

    # Add indexes for performance
    add_index :survey_engine_questions, :is_matrix_question
    add_index :survey_engine_questions, [ :matrix_parent_id, :order_position ], name: 'idx_matrix_questions_parent_order'
  end
end
