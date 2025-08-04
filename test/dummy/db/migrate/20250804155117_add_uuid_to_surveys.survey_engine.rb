# This migration comes from survey_engine (originally 20250722203637)
class AddUuidToSurveys < ActiveRecord::Migration[7.1]
  def change
    add_column :survey_engine_surveys, :uuid, :string
    add_index :survey_engine_surveys, :uuid, unique: true
  end
end
