require "test_helper"

module SurveyEngine
  # Las relaciones de Question hacia sí misma tienen que nombrar la clase con su módulo.
  #
  # Con `class_name: "Question"`, Rails (ActiveRecord::Reflection#_klass) ve que el nombre es
  # igual al de la clase dueña sin su módulo y busca primero `::Question`, la de nivel
  # superior. En la app dummy no existe y cae en SurveyEngine::Question, pero en una app que
  # tenga su propio modelo Question (empieza2, con las preguntas de sus quizzes) las relaciones
  # apuntaban a ese modelo: validar una fila de matriz reventaba (is_matrix_question? no existe
  # ahí) y la validación de las respuestas de matriz comparaba con una pregunta ajena.
  class QuestionClassNameTest < ActiveSupport::TestCase
    RELACIONES = %i[conditional_parent conditional_questions matrix_parent matrix_sub_questions].freeze

    # Un Question de nivel superior, como el que tiene la app que usa la gema.
    setup do
      ::Object.const_set(:Question, Class.new(ActiveRecord::Base) { self.table_name = "survey_engine_questions" })
      RELACIONES.each { |nombre| Question.reflect_on_association(nombre).instance_variable_set(:@klass, nil) }
    end

    teardown do
      ::Object.send(:remove_const, :Question)
      RELACIONES.each { |nombre| Question.reflect_on_association(nombre).instance_variable_set(:@klass, nil) }
    end

    test "las relaciones de una pregunta consigo misma apuntan a SurveyEngine::Question aunque la app tenga su propio Question" do
      RELACIONES.each do |nombre|
        assert_equal SurveyEngine::Question, SurveyEngine::Question.reflect_on_association(nombre).klass, nombre
      end
    end
  end
end
