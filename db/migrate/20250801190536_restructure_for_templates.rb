class RestructureForTemplates < ActiveRecord::Migration[7.1]
  def up
    # Clear all existing data - clean slate approach (SQLite compatible)
    execute "DELETE FROM survey_engine_answer_options"
    execute "DELETE FROM survey_engine_answers"
    execute "DELETE FROM survey_engine_responses"
    execute "DELETE FROM survey_engine_participants"
    execute "DELETE FROM survey_engine_options"
    execute "DELETE FROM survey_engine_questions"
    execute "DELETE FROM survey_engine_surveys"

    # Remove unwanted columns from surveys
    remove_column :survey_engine_surveys, :description, :text if column_exists?(:survey_engine_surveys, :description)
    remove_column :survey_engine_surveys, :published_at, :datetime if column_exists?(:survey_engine_surveys, :published_at)
    remove_column :survey_engine_surveys, :expires_at, :datetime if column_exists?(:survey_engine_surveys, :expires_at)
    remove_column :survey_engine_surveys, :status, :string if column_exists?(:survey_engine_surveys, :status)

    # Create survey_templates table
    create_table :survey_engine_survey_templates do |t|
      t.string :name, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :survey_engine_survey_templates, :name
    add_index :survey_engine_survey_templates, :is_active

    # Modify questions to reference templates instead of surveys
    remove_column :survey_engine_questions, :survey_id, :bigint if column_exists?(:survey_engine_questions, :survey_id)
    add_reference :survey_engine_questions, :survey_template, null: false, foreign_key: { to_table: :survey_engine_survey_templates }

    # Add template reference to surveys
    add_reference :survey_engine_surveys, :survey_template, null: false, foreign_key: { to_table: :survey_engine_survey_templates }
  end

  def down
    # This migration is destructive and not easily reversible
    # You would need to restore from backup to rollback
    raise ActiveRecord::IrreversibleMigration, "This migration destroys data and cannot be reversed"
  end
end
