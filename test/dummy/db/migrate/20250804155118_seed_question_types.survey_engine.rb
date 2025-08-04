# This migration comes from survey_engine (originally 20250722214044)
class SeedQuestionTypes < ActiveRecord::Migration[7.1]
  def up
    question_types = [
      {
        name: "text",
        description: "Free text input",
        allows_options: false,
        allows_multiple_selections: false
      },
      {
        name: "single_choice", 
        description: "Single selection",
        allows_options: true,
        allows_multiple_selections: false
      },
      {
        name: "multiple_choice",
        description: "Multiple selections allowed",
        allows_options: true,
        allows_multiple_selections: true
      },
      {
        name: "scale",
        description: "Numeric scale",
        allows_options: false,
        allows_multiple_selections: false
      },
      {
        name: "boolean",
        description: "Yes/No questions",
        allows_options: false,
        allows_multiple_selections: false
      },
      {
        name: "number",
        description: "Numeric input",
        allows_options: false,
        allows_multiple_selections: false
      }
    ]

    question_types.each do |qt_data|
      SurveyEngine::QuestionType.find_or_create_by(name: qt_data[:name]) do |qt|
        qt.description = qt_data[:description]
        qt.allows_options = qt_data[:allows_options]
        qt.allows_multiple_selections = qt_data[:allows_multiple_selections]
      end
    end
  end

  def down
    SurveyEngine::QuestionType.where(
      name: ["text", "single_choice", "multiple_choice", "scale", "boolean", "number"]
    ).destroy_all
  end
end
