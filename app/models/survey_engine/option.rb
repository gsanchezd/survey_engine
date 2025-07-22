module SurveyEngine
  class Option < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    belongs_to :question
    has_many :answer_options, dependent: :destroy

    validates :option_text, presence: true, length: { maximum: 255 }
    validates :option_value, presence: true, length: { maximum: 100 }
    validates :order_position, presence: true, uniqueness: { scope: :question_id }
    validates :is_other, inclusion: { in: [true, false] }
    validates :is_exclusive, inclusion: { in: [true, false] }
    validates :is_active, inclusion: { in: [true, false] }

    validate :only_one_other_option_per_question
    validate :exclusive_and_other_are_mutually_exclusive

    before_validation :set_next_order_position, if: :new_record?
    before_validation :set_default_option_value, if: :new_record?

    scope :ordered, -> { order(:order_position) }
    scope :active, -> { where(is_active: true) }
    scope :inactive, -> { where(is_active: false) }
    scope :other_options, -> { where(is_other: true) }
    scope :regular_options, -> { where(is_other: false) }
    scope :exclusive_options, -> { where(is_exclusive: true) }

    def other?
      is_other?
    end

    def exclusive?
      is_exclusive?
    end

    def active?
      is_active?
    end

    def skip_logic_hash
      return {} if skip_logic.blank?
      
      JSON.parse(skip_logic)
    rescue JSON::ParserError
      {}
    end

    def set_skip_logic(logic_hash)
      self.skip_logic = logic_hash.to_json
    end

    def deactivate!
      update!(is_active: false)
    end

    def activate!
      update!(is_active: true)
    end

    private

    def set_next_order_position
      return if order_position.present?
      
      max_position = question&.options&.maximum(:order_position) || 0
      self.order_position = max_position + 1
    end

    def set_default_option_value
      return if option_value.present?
      
      # Generate a simple value based on text if not provided
      self.option_value = option_text&.parameterize&.underscore || "option_#{order_position}"
    end

    def only_one_other_option_per_question
      return unless is_other? && question.present?

      existing_other = question.options.where(is_other: true)
      existing_other = existing_other.where.not(id: id) unless new_record?
      
      if existing_other.exists?
        errors.add(:is_other, 'solo puede haber una opción "Otro" por pregunta')
      end
    end

    def exclusive_and_other_are_mutually_exclusive
      if is_other? && is_exclusive?
        errors.add(:is_exclusive, 'no puede ser exclusiva y "Otro" al mismo tiempo')
      end
    end
  end
end