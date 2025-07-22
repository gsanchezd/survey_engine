module SurveyEngine
  class Question < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :survey
    belongs_to :question_type
    has_many :options, dependent: :destroy
    has_many :answers, dependent: :destroy

    validates :title, presence: true, length: { maximum: 500 }
    validates :description, length: { maximum: 1000 }
    validates :order_position, presence: true, uniqueness: { scope: :survey_id }
    validates :is_required, inclusion: { in: [true, false] }
    validates :allow_other, inclusion: { in: [true, false] }
    validates :randomize_options, inclusion: { in: [true, false] }
    validates :max_characters, numericality: { greater_than: 0, allow_nil: true }
    validates :min_selections, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validates :max_selections, numericality: { greater_than: 0, allow_nil: true }
    validates :scale_min, numericality: { allow_nil: true }
    validates :scale_max, numericality: { allow_nil: true }

    validate :scale_range_is_valid
    validate :selection_range_is_valid
    validate :question_type_compatibility

    before_validation :set_next_order_position, if: :new_record?

    scope :ordered, -> { order(:order_position) }
    scope :required, -> { where(is_required: true) }
    scope :optional, -> { where(is_required: false) }

    def required?
      is_required?
    end

    def supports_options?
      question_type&.supports_options?
    end

    def supports_multiple_selections?
      question_type&.supports_multiple_selections?
    end

    def options_count
      options.count
    end

    def has_other_option?
      allow_other? && options.where(is_other: true).exists?
    end

    def validation_rules_hash
      return {} if validation_rules.blank?
      
      JSON.parse(validation_rules)
    rescue JSON::ParserError
      {}
    end

    def set_validation_rules(rules_hash)
      self.validation_rules = rules_hash.to_json
    end

    private

    def set_next_order_position
      return if order_position.present?
      
      max_position = survey&.questions&.maximum(:order_position) || 0
      self.order_position = max_position + 1
    end

    def scale_range_is_valid
      return unless scale_min.present? && scale_max.present?
      
      errors.add(:scale_max, 'debe ser mayor que el valor mínimo') if scale_max <= scale_min
    end

    def selection_range_is_valid
      return unless min_selections.present? && max_selections.present?
      
      errors.add(:max_selections, 'debe ser mayor o igual que el mínimo de selecciones') if max_selections < min_selections
    end

    def question_type_compatibility
      return unless question_type.present?

      # Validate options-related fields
      unless question_type.supports_options?
        errors.add(:allow_other, 'no es compatible con este tipo de pregunta') if allow_other?
        errors.add(:randomize_options, 'no es compatible con este tipo de pregunta') if randomize_options?
        errors.add(:min_selections, 'no es compatible con este tipo de pregunta') if min_selections.present?
        errors.add(:max_selections, 'no es compatible con este tipo de pregunta') if max_selections.present?
      end

      # Validate multiple selection fields
      unless question_type.supports_multiple_selections?
        if max_selections.present? && max_selections > 1
          errors.add(:max_selections, 'debe ser 1 para este tipo de pregunta')
        end
      end
    end
  end
end