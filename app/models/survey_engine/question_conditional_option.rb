module SurveyEngine
  class QuestionConditionalOption < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :question
    belongs_to :option

    validates :question_id, presence: true
    validates :option_id, presence: true
    validates :question_id, uniqueness: { scope: :option_id, message: "can only have one conditional relationship per option" }

    # Validate that the option belongs to the parent question
    validate :option_belongs_to_parent_question

    private

    def option_belongs_to_parent_question
      return unless question.present? && option.present?
      return unless question.conditional_parent.present?

      unless option.question_id == question.conditional_parent_id
        errors.add(:option, "must belong to the parent question")
      end
    end
  end
end
