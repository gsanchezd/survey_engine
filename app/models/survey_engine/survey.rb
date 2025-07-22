module SurveyEngine
  class Survey < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    has_many :questions, dependent: :destroy
    has_many :participants, dependent: :destroy
    has_many :responses, dependent: :destroy
    has_many :settings, dependent: :destroy

    validates :title, presence: true, length: { maximum: 255 }
    validates :description, length: { maximum: 2000 }
    validates :status, presence: true, inclusion: { in: %w[draft published paused archived] }
    validates :is_active, inclusion: { in: [true, false] }
    validates :global, inclusion: { in: [true, false] }

    validate :published_at_before_expires_at

    enum :status, {
      draft: 'draft',
      published: 'published', 
      paused: 'paused',
      archived: 'archived'
    }

    scope :active, -> { where(is_active: true) }
    scope :inactive, -> { where(is_active: false) }
    scope :global_surveys, -> { where(global: true) }
    scope :local_surveys, -> { where(global: false) }
    scope :published, -> { where(status: 'published') }
    scope :current, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
    scope :expired, -> { where('expires_at < ?', Time.current) }

    def active?
      is_active && (status == 'published')
    end

    def expired?
      expires_at.present? && expires_at < Time.current
    end

    def current?
      !expired?
    end

    def published?
      status == 'published'
    end

    def can_receive_responses?
      active? && current?
    end

    def questions_count
      questions.count
    end

    def responses_count
      responses.count
    end

    def participants_count
      participants.count
    end

    def publish!
      update!(status: 'published', is_active: true, published_at: Time.current)
    end

    def pause!
      update!(status: 'paused', is_active: false)
    end

    def archive!
      update!(status: 'archived', is_active: false)
    end

    def setting(key)
      settings.find_by(setting_key: key)&.setting_value
    end

    def set_setting(key, value)
      setting_record = settings.find_or_initialize_by(setting_key: key)
      setting_record.setting_value = value.to_s
      setting_record.save!
    end

    private

    def published_at_before_expires_at
      return unless published_at.present? && expires_at.present?
      
      errors.add(:expires_at, 'debe ser posterior a la fecha de publicación') if expires_at <= published_at
    end
  end
end