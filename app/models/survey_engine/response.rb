module SurveyEngine
  class Response < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :survey
    belongs_to :participant
    has_many :answers, dependent: :destroy

    validates :survey_id, presence: true
    validates :participant_id, presence: true
    validate :participant_belongs_to_survey

    before_destroy :revert_participant_status

    scope :completed, -> { where.not(completed_at: nil) }
    scope :by_completion_date, -> { order(:completed_at) }
    scope :recent, -> { order(created_at: :desc) }

    def completed?
      completed_at.present?
    end

    def complete!
      update!(completed_at: Time.current)
    end

    def completion_time
      return nil unless completed? && created_at.present?
      
      completed_at - created_at
    end

    def answers_count
      answers.count
    end

    def completion_percentage
      visible_questions = visible_questions_for_response
      total_visible = visible_questions.count
      
      return 100 if total_visible == 0  # No questions to answer means complete
      
      answered_questions = answers.joins(:question)
                                  .where(question: visible_questions)
                                  .count
      
      (answered_questions.to_f / total_visible * 100).round(2)
    end
    
    # Get questions that should be visible based on conditional logic and answers
    def visible_questions_for_response
      all_questions = survey.questions.where(is_matrix_question: [false, nil])
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
    
    private
    
    def should_show_conditional_question?(question)
      return true unless question.conditional_parent_id
      
      parent_answer = answers.find_by(question_id: question.conditional_parent_id)
      return false unless parent_answer  # Parent not answered, so child is hidden
      
      # Check if the condition is met based on the parent's answer
      parent_value = case question.conditional_parent.question_type.name
                     when 'scale', 'number'
                       parent_answer.numeric_answer
                     when 'boolean'
                       parent_answer.boolean_answer ? 1 : 0
                     when 'single_choice'
                       parent_answer.options.first&.option_value&.to_i
                     else
                       nil
                     end
      
      return false if parent_value.nil?
      
      # Evaluate the condition
      if question.conditional_logic_type == 'range'
        evaluate_range_condition(parent_value, question)
      else
        evaluate_single_condition(parent_value, question)
      end
    end
    
    def evaluate_single_condition(value, question)
      target = question.conditional_value.to_f
      
      case question.conditional_operator
      when 'equal_to'
        result = value == target
      when 'not_equals'
        result = value != target
      when 'greater_than'
        result = value > target
      when 'greater_than_or_equal'
        result = value >= target
      when 'less_than'
        result = value < target
      when 'less_than_or_equal'
        result = value <= target
      else
        result = false
      end
      
      question.show_if_condition_met ? result : !result
    end
    
    def evaluate_range_condition(value, question)
      min_value = question.conditional_value.to_f
      max_value = question.conditional_value_2.to_f
      
      in_range = case [question.conditional_operator, question.conditional_operator_2]
                 when ['greater_than_or_equal', 'less_than_or_equal']
                   value >= min_value && value <= max_value
                 when ['greater_than', 'less_than']
                   value > min_value && value < max_value
                 when ['greater_than_or_equal', 'less_than']
                   value >= min_value && value < max_value
                 when ['greater_than', 'less_than_or_equal']
                   value > min_value && value <= max_value
                 else
                   false
                 end
      
      question.show_if_condition_met ? in_range : !in_range
    end
    
    public

    def answered_question_ids
      answers.pluck(:question_id)
    end

    def unanswered_questions
      answered_ids = answered_question_ids
      # Only return visible questions that haven't been answered
      visible_questions_for_response.reject { |q| answered_ids.include?(q.id) }
    end

    def answer_for_question(question)
      answers.find_by(question: question)
    end

    def self.completion_rate_by_day
      completed
        .group("DATE(completed_at)")
        .count
    end

    private

    def participant_belongs_to_survey
      return unless participant.present? && survey.present?
      
      unless participant.survey_id == survey.id
        errors.add(:participant, "must belong to the same survey")
      end
    end

    def revert_participant_status
      return unless participant.present?
      
      # Revert participant back to invited status
      participant.update!(
        status: 'invited',
        completed_at: nil
      )
    end
  end
end