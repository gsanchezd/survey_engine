module SurveyEngine
  class SurveyTemplate < ApplicationRecord
    self.table_name_prefix = "survey_engine_"

    has_many :questions, dependent: :destroy
    has_many :surveys, dependent: :restrict_with_exception
    has_many :options, through: :questions

    validates :name, presence: true

    scope :active, -> { where(is_active: true) }
    scope :ordered, -> { order(:name) }

    def questions_count
      questions.count
    end

    def surveys_count
      surveys.count
    end

    def can_be_deleted?
      surveys.empty?
    end
  end
end