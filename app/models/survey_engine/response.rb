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
      QuestionVisibilityService.new(self).visible_questions
    end

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