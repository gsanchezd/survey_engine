module SurveyEngine
  class AnswerOption < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :answer
    belongs_to :option

    validates :answer_id, presence: true, unless: :new_record_with_built_answer?
    validates :option_id, presence: true
    validates :answer_id, uniqueness: { scope: :option_id, message: "cannot select the same option twice" }
    validate :option_belongs_to_same_question

    scope :recent, -> { order(created_at: :desc) }

    delegate :option_text, :option_value, :is_other?, :is_exclusive?, to: :option

    private

    def new_record_with_built_answer?
      new_record? && answer.present? && answer.new_record?
    end

    def option_belongs_to_same_question
      return unless answer.present? && option.present?
      
      # For matrix questions, options belong to the parent matrix question,
      # but answers belong to the matrix sub-questions (rows)
      answer_question = answer.question
      
      if answer_question.is_matrix_row?
        # Check if option belongs to the parent matrix question
        parent_question = answer_question.matrix_parent
        unless parent_question && option.question_id == parent_question.id
          errors.add(:option, "must belong to the same question as the answer")
        end
      else
        # Regular validation for non-matrix questions
        unless answer.question_id == option.question_id
          errors.add(:option, "must belong to the same question as the answer")
        end
      end
    end
  end
end