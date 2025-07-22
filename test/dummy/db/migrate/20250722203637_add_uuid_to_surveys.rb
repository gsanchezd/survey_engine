class AddUuidToSurveys < ActiveRecord::Migration[8.0]
  def change
    add_column :survey_engine_surveys, :uuid, :string
    add_index :survey_engine_surveys, :uuid, unique: true
  end
end
