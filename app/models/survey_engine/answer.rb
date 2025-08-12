module SurveyEngine
  class Answer < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    def self.ransackable_attributes(auth_object = nil)
      %w[id response_id question_id text_answer numeric_answer decimal_answer
         boolean_answer other_text answered_at selection_count created_at updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      %w[response question answer_options options]
    end

    belongs_to :response
    belongs_to :question
    has_many :answer_options, dependent: :destroy
    has_many :options, through: :answer_options

    accepts_nested_attributes_for :answer_options, allow_destroy: true

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
      !boolean_answer.nil? ||
      answer_options.any? ||
      answer_options.loaded?
    end

    def display_value
      return text_answer if text_answer.present?
      return numeric_answer.to_s if numeric_answer.present?
      return decimal_answer.to_s if decimal_answer.present?
      return boolean_answer? ? "Yes" : "No" if boolean_answer.present?
      return ranking_display_value if question.is_ranking_question? && answer_options.any?
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

    def ranked_options
      return [] unless question.is_ranking_question?
      answer_options.includes(:option).by_ranking_order
    end

    def ranking_display_value
      return display_value unless question.is_ranking_question?

      ranked_options.map.with_index(1) do |answer_option, index|
        "#{index}. #{answer_option.option_text}"
      end.join(", ")
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

      unless response.survey.survey_template == question.survey_template
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
      when "text", "textarea", "email"
        unless text_answer.present?
          errors.add(:text_answer, "is required for text questions")
        end
      when "scale", "number"
        unless numeric_answer.present?
          errors.add(:numeric_answer, "is required for scale questions")
        end
      when "boolean"
        if boolean_answer.nil?
          errors.add(:boolean_answer, "is required for boolean questions")
        end
      when "single_choice", "multiple_choice", "matrix_scale"
        # Check both persisted and built associations
        has_options = answer_options.any? || answer_options.loaded? || answer_options.size > 0
        unless has_options
          errors.add(:base, "Must select at least one option for choice questions")
        end

        option_count = answer_options.loaded? ? answer_options.size : answer_options.count
        if (question_type == "single_choice" || question_type == "matrix_scale") && option_count > 1
          errors.add(:base, "Can only select one option for single choice questions")
        end
      when "ranking"
        # Ranking questions require all options to be ranked
        has_options = answer_options.any? || answer_options.loaded? || answer_options.size > 0
        unless has_options
          errors.add(:base, :must_rank_all_options)
          return
        end

        # Validate that all answer_options have ranking_order
        if answer_options.any? { |ao| ao.ranking_order.blank? }
          errors.add(:base, "All selected options must have a ranking order")
          return
        end

        # Validate that ALL question options are ranked (no missing options)
        question_option_count = question.options.count
        ranked_option_count = answer_options.size

        if ranked_option_count != question_option_count
          errors.add(:base, :must_rank_all_options_with_count, count: question_option_count, ranked: ranked_option_count)
          return
        end

        # Validate that ranking orders are sequential and complete (1, 2, 3, ...)
        ranking_orders = answer_options.map(&:ranking_order).compact.sort
        expected_orders = (1..question_option_count).to_a

        unless ranking_orders == expected_orders
          errors.add(:base, :ranking_order_sequential, count: question_option_count)
        end
      end
    end
  end
end
