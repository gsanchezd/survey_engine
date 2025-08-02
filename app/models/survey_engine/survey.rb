module SurveyEngine
  class Survey < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    def self.ransackable_attributes(auth_object = nil)
      %w[id title uuid is_active global surveyable_type surveyable_id survey_template_id created_at updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      %w[survey_template participants responses questions options]
    end

    belongs_to :survey_template
    belongs_to :surveyable, polymorphic: true, optional: true
    has_many :participants, dependent: :destroy
    has_many :responses, dependent: :destroy
    # has_many :settings, dependent: :destroy  # Will be added when Settings model is created

    # Delegate to template
    has_many :questions, through: :survey_template
    has_many :options, through: :questions

    validates :title, presence: true, length: { maximum: 255 }
    validates :is_active, inclusion: { in: [ true, false ] }
    validates :global, inclusion: { in: [ true, false ] }
    validates :uuid, presence: true, uniqueness: true

    before_validation :generate_uuid, on: :create

    scope :active, -> { where(is_active: true) }
    scope :inactive, -> { where(is_active: false) }
    scope :global_surveys, -> { where(global: true) }
    scope :local_surveys, -> { where(global: false) }
    scope :for_surveyable, ->(surveyable) { where(surveyable: surveyable) }
    scope :for_surveyable_type, ->(type) { where(surveyable_type: type) }

    # Use UUID for URLs instead of ID
    def to_param
      uuid
    end

    def active?
      is_active
    end

    def questions_count
      questions.count
    end

    def participants_count
      participants.count
    end

    def responses_count
      responses.count
    end

    def completed_responses_count
      responses.completed.count
    end

    def can_receive_responses?
      is_active
    end

    # Get setting value (when Settings model is implemented)
    # def get_setting(key, default = nil)
    #   setting = settings.find_by(setting_key: key)
    #   setting&.setting_value || default
    # end

    # Set setting value (when Settings model is implemented)
    # def set_setting(key, value)
    #   setting_record = settings.find_or_initialize_by(setting_key: key)
    #   setting_record.setting_value = value.to_s
    #   setting_record.save!
    # end

    private

    def generate_uuid
      self.uuid ||= SecureRandom.uuid
    end
  end
end