class FixQuestionsOrderPositionConstraint < ActiveRecord::Migration[8.0]
  def up
    # Remove the old uniqueness constraint on order_position
    remove_index :survey_engine_questions, :order_position if index_exists?(:survey_engine_questions, :order_position)
  end
  
  def down
    # Add back the constraint if needed (though this might cause issues)
    add_index :survey_engine_questions, :order_position, unique: true if !index_exists?(:survey_engine_questions, :order_position)
  end
end
