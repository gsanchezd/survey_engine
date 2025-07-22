module SurveyEngine
  class Participant < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :survey
    has_one :response, dependent: :destroy

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :status, presence: true, inclusion: { in: %w[invited completed] }
    validates :email, uniqueness: { scope: :survey_id, message: "has already been registered for this survey" }

    enum :status, {
      invited: 'invited',
      completed: 'completed'
    }

    scope :completed, -> { where(status: 'completed') }
    scope :invited, -> { where(status: 'invited') }
    scope :pending, -> { where(status: 'invited') }

    def completed?
      status == 'completed'
    end

    def pending?
      status == 'invited'
    end

    def complete!
      update!(status: 'completed', completed_at: Time.current)
    end

    def completion_time
      return nil unless completed?
      return nil unless completed_at.present? && created_at.present?
      
      completed_at - created_at
    end

    def self.completion_rate_for_survey(survey)
      participants = where(survey: survey)
      return 0 if participants.count == 0
      
      completed_count = participants.completed.count
      (completed_count.to_f / participants.count * 100).round(2)
    end
  end
end