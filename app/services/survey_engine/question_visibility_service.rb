module SurveyEngine
  class QuestionVisibilityService
    attr_reader :response

    def initialize(response)
      @response = response
    end

    # Get all questions that should be visible for this response
    def visible_questions
      @visible_questions ||= calculate_visible_questions
    end

    # Check if a specific question was shown to this respondent
    def question_was_shown?(question)
      visible_questions.include?(question)
    end

    # Get all possible questions for the survey (excluding matrix parents)
    def all_answerable_questions
      @all_answerable_questions ||= response.survey.questions
        .where(is_matrix_question: [ false, nil ])
    end

    private

    def calculate_visible_questions
      all_questions = response.survey.questions.where(is_matrix_question: [ false, nil ])
      visible = []

      all_questions.each do |question|
        if question.conditional_parent_id.nil?
          # Non-conditional questions are always visible
          visible << question
        elsif should_show_conditional_question?(question)
          # Conditional questions only if their conditions are met
          visible << question
        end
      end

      visible
    end

    def should_show_conditional_question?(question)
      return true unless question.conditional_parent_id

      parent_answer = response.answers.find_by(question_id: question.conditional_parent_id)
      return false unless parent_answer  # Parent not answered, so child is hidden

      # Use the question's should_show? method which handles both scale and option conditionals
      question.should_show?(parent_answer)
    end

    def extract_answer_value(answer, question)
      case question.question_type.name
      when "scale", "number"
        answer.numeric_answer
      when "boolean"
        answer.boolean_answer ? 1 : 0
      when "single_choice"
        answer.options.first&.option_value&.to_i
      else
        nil
      end
    end

    def evaluate_single_condition(value, question)
      target = question.conditional_value.to_f

      result = case question.conditional_operator
      when "equal_to"
        value == target
      when "not_equals"
        value != target
      when "greater_than"
        value > target
      when "greater_than_or_equal"
        value >= target
      when "less_than"
        value < target
      when "less_than_or_equal"
        value <= target
      else
        false
      end

      question.show_if_condition_met ? result : !result
    end

    def evaluate_range_condition(value, question)
      min_value = question.conditional_value.to_f
      max_value = question.conditional_value_2.to_f

      in_range = case [ question.conditional_operator, question.conditional_operator_2 ]
      when [ "greater_than_or_equal", "less_than_or_equal" ]
        value >= min_value && value <= max_value
      when [ "greater_than", "less_than" ]
        value > min_value && value < max_value
      when [ "greater_than_or_equal", "less_than" ]
        value >= min_value && value < max_value
      when [ "greater_than", "less_than_or_equal" ]
        value > min_value && value <= max_value
      else
        false
      end

      question.show_if_condition_met ? in_range : !in_range
    end
  end
end
