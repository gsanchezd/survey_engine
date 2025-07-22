module SurveyEngine
  class AnswerOption < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :answer
    belongs_to :option

    validates :answer_id, presence: true
    validates :option_id, presence: true
    validates :answer_id, uniqueness: { scope: :option_id, message: "cannot select the same option twice" }
    validate :option_belongs_to_same_question

    scope :recent, -> { order(created_at: :desc) }

    delegate :option_text, :option_value, :is_other?, :is_exclusive?, to: :option

    private

    def option_belongs_to_same_question
      return unless answer.present? && option.present?
      
      unless answer.question_id == option.question_id
        errors.add(:option, "must belong to the same question as the answer")
      end
    end
  end
end