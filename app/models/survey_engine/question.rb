module SurveyEngine
  class Question < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    def self.ransackable_attributes(auth_object = nil)
      %w[id title description order_position is_required allow_other randomize_options 
         max_characters min_selections max_selections scale_min scale_max scale_min_label 
         scale_max_label placeholder_text help_text survey_template_id question_type_id
         conditional_parent_id conditional_operator conditional_value conditional_operator_2 
         conditional_value_2 conditional_logic_type show_if_condition_met created_at updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      %w[survey_template question_type conditional_parent conditional_questions options answers]
    end

    belongs_to :survey_template, counter_cache: true
    belongs_to :question_type
    belongs_to :conditional_parent, class_name: 'Question', optional: true
    has_many :conditional_questions, class_name: 'Question', foreign_key: 'conditional_parent_id', dependent: :destroy
    belongs_to :matrix_parent, class_name: 'Question', optional: true
    has_many :matrix_sub_questions, class_name: 'Question', foreign_key: 'matrix_parent_id', dependent: :destroy
    has_many :options, dependent: :destroy
    has_many :answers, dependent: :destroy

    validates :title, presence: true, length: { maximum: 500 }
    validates :description, length: { maximum: 1000 }
    validates :order_position, presence: true
    validates :is_required, inclusion: { in: [true, false] }
    validates :allow_other, inclusion: { in: [true, false] }
    validates :randomize_options, inclusion: { in: [true, false] }
    validates :max_characters, numericality: { greater_than: 0, allow_nil: true }
    validates :min_selections, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validates :max_selections, numericality: { greater_than: 0, allow_nil: true }
    validates :scale_min, numericality: { allow_nil: true }
    validates :scale_max, numericality: { allow_nil: true }
    validates :conditional_operator, inclusion: { in: %w[less_than greater_than equal_to greater_than_or_equal less_than_or_equal], allow_nil: true }
    validates :conditional_value, numericality: { allow_nil: true }
    validates :conditional_operator_2, inclusion: { in: %w[less_than greater_than equal_to greater_than_or_equal less_than_or_equal], allow_nil: true }
    validates :conditional_value_2, numericality: { allow_nil: true }
    validates :conditional_logic_type, inclusion: { in: %w[single and or range], allow_nil: true }
    validates :show_if_condition_met, inclusion: { in: [true, false], allow_nil: true }

    validate :scale_range_is_valid
    validate :selection_range_is_valid
    validate :question_type_compatibility
    validate :conditional_logic_is_valid
    validate :matrix_structure_is_valid

    before_validation :set_next_order_position, if: :new_record?

    scope :ordered, -> { order(:order_position) }
    scope :required, -> { where(is_required: true) }
    scope :optional, -> { where(is_required: false) }
    scope :root_questions, -> { where(conditional_parent_id: nil) }
    scope :conditional_questions, -> { where.not(conditional_parent_id: nil) }
    scope :matrix_questions, -> { where(is_matrix_question: true) }
    scope :matrix_rows, -> { where.not(matrix_parent_id: nil) }
    scope :non_matrix_questions, -> { where(is_matrix_question: false, matrix_parent_id: nil) }

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

    def is_conditional?
      conditional_parent_id.present?
    end

    def has_conditional_questions?
      conditional_questions.any?
    end

    def is_scale_question?
      question_type&.name == 'scale'
    end

    def is_matrix?
      is_matrix_question?
    end

    def is_matrix_row?
      matrix_parent_id.present?
    end

    def matrix_type?
      return false unless is_matrix?
      question_type&.name&.start_with?('matrix_')
    end

    def matrix_scale?
      question_type&.name == 'matrix_scale'
    end

    def matrix_choice?
      question_type&.name == 'matrix_choice'
    end

    def is_ranking_question?
      question_type&.name == 'ranking'
    end

    # For matrix rows, use parent's options
    def effective_options
      if is_matrix_row? && matrix_parent.present?
        matrix_parent.options.ordered
      else
        options.ordered
      end
    end

    def evaluate_condition(answer_value)
      return true unless is_conditional?
      return false if conditional_operator.blank? || conditional_value.blank?

      # Handle complex conditional logic (AND, OR, range)
      case conditional_logic_type
      when 'and'
        evaluate_single_condition(answer_value, conditional_operator, conditional_value) &&
        evaluate_single_condition(answer_value, conditional_operator_2, conditional_value_2)
      when 'or'
        evaluate_single_condition(answer_value, conditional_operator, conditional_value) ||
        evaluate_single_condition(answer_value, conditional_operator_2, conditional_value_2)
      when 'range'
        # For range conditions, assume first condition is >= and second is <=
        # This handles cases like NPS Passives (7-8): score >= 7 AND score <= 8
        evaluate_single_condition(answer_value, conditional_operator, conditional_value) &&
        evaluate_single_condition(answer_value, conditional_operator_2, conditional_value_2)
      else
        # Default single condition logic
        evaluate_single_condition(answer_value, conditional_operator, conditional_value)
      end
    end

    private

    def evaluate_single_condition(answer_value, operator, value)
      return false if operator.blank? || value.blank?

      case operator
      when 'less_than'
        answer_value < value
      when 'greater_than'
        answer_value > value
      when 'equal_to'
        answer_value == value
      when 'greater_than_or_equal'
        answer_value >= value
      when 'less_than_or_equal'
        answer_value <= value
      else
        false
      end
    end

    public

    def should_show?(parent_answer_value = nil)
      return true unless is_conditional?
      return false if conditional_parent.blank?
      return false if parent_answer_value.nil?

      condition_met = evaluate_condition(parent_answer_value)
      show_if_condition_met? ? condition_met : !condition_met
    end

    def next_questions_for_answer(answer_value)
      return [] unless has_conditional_questions?
      
      conditional_questions.select do |question|
        question.should_show?(answer_value)
      end
    end

    private

    def set_next_order_position
      return if order_position.present?
      
      max_position = survey_template&.questions&.maximum(:order_position) || 0
      self.order_position = max_position + 1
    end

    def scale_range_is_valid
      return unless scale_min.present? && scale_max.present?
      
      errors.add(:scale_max, 'must be greater than minimum value') if scale_max <= scale_min
    end

    def selection_range_is_valid
      return unless min_selections.present? && max_selections.present?
      
      errors.add(:max_selections, 'must be greater than or equal to minimum selections') if max_selections < min_selections
    end

    def question_type_compatibility
      return unless question_type.present?

      # Validate options-related fields
      unless question_type.supports_options?
        errors.add(:allow_other, 'is not compatible with this question type') if allow_other?
        errors.add(:randomize_options, 'is not compatible with this question type') if randomize_options?
        errors.add(:min_selections, 'is not compatible with this question type') if min_selections.present?
        errors.add(:max_selections, 'is not compatible with this question type') if max_selections.present?
      end

      # Validate multiple selection fields
      unless question_type.supports_multiple_selections?
        if max_selections.present? && max_selections > 1
          errors.add(:max_selections, 'must be 1 for this question type')
        end
      end
    end

    def conditional_logic_is_valid
      return unless conditional_parent_id.present?

      # Validate conditional parent exists and is from same template
      if conditional_parent.present?
        errors.add(:conditional_parent, 'must be from the same survey template') if conditional_parent.survey_template_id != survey_template_id
        errors.add(:conditional_parent, 'must be a scale question') unless conditional_parent.is_scale_question?
        errors.add(:conditional_parent, 'cannot be a conditional question itself') if conditional_parent.is_conditional?
      end

      # Validate conditional fields are present together
      if conditional_operator.present? || conditional_value.present?
        errors.add(:conditional_operator, 'is required for conditional questions') if conditional_operator.blank?
        errors.add(:conditional_value, 'is required for conditional questions') if conditional_value.blank?
      end

      # Validate conditional value is within parent's scale range
      if conditional_parent&.is_scale_question? && conditional_value.present?
        if conditional_parent.scale_min.present? && conditional_value < conditional_parent.scale_min
          errors.add(:conditional_value, 'must be within parent question scale range')
        end
        if conditional_parent.scale_max.present? && conditional_value > conditional_parent.scale_max
          errors.add(:conditional_value, 'must be within parent question scale range')
        end
      end

      # Validate complex conditional logic
      if conditional_logic_type.present? && conditional_logic_type != 'single'
        # For complex logic, second condition fields are required
        if conditional_operator_2.present? || conditional_value_2.present?
          errors.add(:conditional_operator_2, 'is required for complex conditional logic') if conditional_operator_2.blank?
          errors.add(:conditional_value_2, 'is required for complex conditional logic') if conditional_value_2.blank?
        else
          errors.add(:conditional_operator_2, 'is required for complex conditional logic')
          errors.add(:conditional_value_2, 'is required for complex conditional logic')
        end

        # Validate second conditional value is within parent's scale range
        if conditional_parent&.is_scale_question? && conditional_value_2.present?
          if conditional_parent.scale_min.present? && conditional_value_2 < conditional_parent.scale_min
            errors.add(:conditional_value_2, 'must be within parent question scale range')
          end
          if conditional_parent.scale_max.present? && conditional_value_2 > conditional_parent.scale_max
            errors.add(:conditional_value_2, 'must be within parent question scale range')
          end
        end

        # Validate range logic makes sense (value1 <= value2 for range conditions)
        if conditional_logic_type == 'range' && conditional_value.present? && conditional_value_2.present?
          if conditional_value > conditional_value_2
            errors.add(:conditional_value_2, 'must be greater than or equal to first conditional value for range logic')
          end
        end
      end
    end

    def matrix_structure_is_valid
      # Matrix parent validations
      if is_matrix_question?
        unless question_type&.name&.start_with?('matrix_')
          errors.add(:question_type, 'must be a matrix type for matrix questions')
        end
        
        if matrix_parent_id.present?
          errors.add(:base, 'Matrix parent cannot have another parent')
        end
        
        if conditional_parent_id.present?
          errors.add(:base, 'Matrix questions cannot be conditional')
        end
      end

      # Matrix row validations
      if matrix_parent_id.present?
        if matrix_parent.blank?
          errors.add(:matrix_parent, 'must exist')
        elsif !matrix_parent.is_matrix_question?
          errors.add(:matrix_parent, 'must be a matrix question')
        elsif matrix_parent.survey_template_id != survey_template_id
          errors.add(:matrix_parent, 'must belong to the same survey template')
        end
        
        if matrix_row_text.blank?
          errors.add(:matrix_row_text, 'is required for matrix rows')
        end
        
        # Matrix rows shouldn't have their own options
        if options.any?
          errors.add(:base, 'Matrix rows cannot have their own options')
        end
      end
    end
  end
end