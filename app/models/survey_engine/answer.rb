module SurveyEngine
  class Answer < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :response
    belongs_to :question
    has_many :answer_options, dependent: :destroy
    has_many :options, through: :answer_options

    validates :response_id, presence: true
    validates :question_id, presence: true
    validates :response_id, uniqueness: { scope: :question_id, message: "can only have one answer per question" }
    validate :response_and_question_belong_to_same_survey
    validate :answer_content_present
    validate :answer_type_matches_question_type
    
    before_validation :set_answered_at, on: :create
    after_save :update_selection_count

    scope :with_text_answers, -> { where.not(text_answer: nil) }
    scope :with_numeric_answers, -> { where.not(numeric_answer: nil) }
    scope :with_boolean_answers, -> { where.not(boolean_answer: nil) }
    scope :recent, -> { order(answered_at: :desc) }

    def has_content?
      text_answer.present? || 
      numeric_answer.present? || 
      decimal_answer.present? || 
      boolean_answer.present? || 
      answer_options.any?
    end

    def display_value
      return text_answer if text_answer.present?
      return numeric_answer.to_s if numeric_answer.present?
      return decimal_answer.to_s if decimal_answer.present?
      return boolean_answer? ? "Yes" : "No" if boolean_answer.present?
      return selected_option_texts.join(", ") if answer_options.any?
      
      "No answer"
    end

    def selected_option_texts
      options.pluck(:option_text)
    end

    def selected_option_values
      options.pluck(:option_value)
    end

    def has_other_text?
      other_text.present?
    end

    def complete_answer
      base_answer = display_value
      return "#{base_answer} (Other: #{other_text})" if has_other_text?
      base_answer
    end

    private

    def set_answered_at
      self.answered_at ||= Time.current
    end

    def update_selection_count
      self.update_column(:selection_count, answer_options.count)
    end

    def response_and_question_belong_to_same_survey
      return unless response.present? && question.present?
      
      unless response.survey_id == question.survey_id
        errors.add(:base, "Response and question must belong to the same survey")
      end
    end

    def answer_content_present
      unless has_content?
        errors.add(:base, "Answer must have at least one type of content")
      end
    end

    def answer_type_matches_question_type
      return unless question.present? && question.question_type.present?
      
      question_type = question.question_type.name
      
      case question_type
      when 'text'
        unless text_answer.present?
          errors.add(:text_answer, "is required for text questions")
        end
      when 'scale'
        unless numeric_answer.present?
          errors.add(:numeric_answer, "is required for scale questions")
        end
      when 'single_choice', 'multiple_choice'
        unless answer_options.any?
          errors.add(:base, "Must select at least one option for choice questions")
        end
        
        if question_type == 'single_choice' && answer_options.count > 1
          errors.add(:base, "Can only select one option for single choice questions")
        end
      end
    end
  end
end