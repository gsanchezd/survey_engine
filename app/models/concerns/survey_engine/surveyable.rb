module SurveyEngine
  module Surveyable
    extend ActiveSupport::Concern

    included do
      has_many :surveys, class_name: 'SurveyEngine::Survey', as: :surveyable, dependent: :destroy
    end

    def active_surveys
      surveys.active
    end

    def published_surveys
      surveys.published
    end

    def current_surveys
      surveys.current
    end

    def survey_responses_count
      surveys.joins(:responses).count
    end

    def survey_participants_count
      surveys.joins(:participants).count
    end

    def can_have_surveys?
      true
    end

    def create_survey(attributes = {})
      surveys.create(attributes)
    end

    def find_survey_by_uuid(uuid)
      surveys.find_by(uuid: uuid)
    end
  end
end