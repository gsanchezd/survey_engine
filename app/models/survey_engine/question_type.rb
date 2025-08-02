module SurveyEngine
  class QuestionType < ApplicationRecord
    def self.table_name_prefix
      "survey_engine_"
    end

    has_many :questions, dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: true
    validates :allows_options, inclusion: { in: [true, false] }
    validates :allows_multiple_selections, inclusion: { in: [true, false] }

    # Standard question types
    STANDARD_TYPES = {
      text: {
        name: 'text',
        description: 'Entrada de texto libre',
        allows_options: false,
        allows_multiple_selections: false
      },
      textarea: {
        name: 'textarea',
        description: 'Área de texto grande',
        allows_options: false,
        allows_multiple_selections: false
      },
      number: {
        name: 'number',
        description: 'Entrada numérica',
        allows_options: false,
        allows_multiple_selections: false
      },
      scale: {
        name: 'scale',
        description: 'Escala Likert o de valoración',
        allows_options: false,
        allows_multiple_selections: false
      },
      single_choice: {
        name: 'single_choice',
        description: 'Selección única (radio buttons)',
        allows_options: true,
        allows_multiple_selections: false
      },
      multiple_choice: {
        name: 'multiple_choice',
        description: 'Selección múltiple (checkboxes)',
        allows_options: true,
        allows_multiple_selections: true
      },
      dropdown_single: {
        name: 'dropdown_single',
        description: 'Lista desplegable de selección única',
        allows_options: true,
        allows_multiple_selections: false
      },
      dropdown_multiple: {
        name: 'dropdown_multiple',
        description: 'Lista desplegable de selección múltiple',
        allows_options: true,
        allows_multiple_selections: true
      },
      boolean: {
        name: 'boolean',
        description: 'Sí/No o Verdadero/Falso',
        allows_options: false,
        allows_multiple_selections: false
      },
      date: {
        name: 'date',
        description: 'Selector de fecha',
        allows_options: false,
        allows_multiple_selections: false
      },
      email: {
        name: 'email',
        description: 'Entrada de email con validación',
        allows_options: false,
        allows_multiple_selections: false
      },
      matrix_scale: {
        name: 'matrix_scale',
        description: 'Matriz de escala Likert',
        allows_options: true,
        allows_multiple_selections: false
      },
      matrix_choice: {
        name: 'matrix_choice',
        description: 'Matriz de selección única',
        allows_options: true,
        allows_multiple_selections: false
      }
    }.freeze

    def self.seed_standard_types
      STANDARD_TYPES.each do |type_key, attributes|
        find_or_create_by(name: attributes[:name]) do |question_type|
          question_type.description = attributes[:description]
          question_type.allows_options = attributes[:allows_options]
          question_type.allows_multiple_selections = attributes[:allows_multiple_selections]
        end
      end
    end

    def supports_options?
      allows_options?
    end

    def supports_multiple_selections?
      allows_multiple_selections?
    end
  end
end