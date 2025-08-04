require 'csv'

module SurveyEngine
  class CsvExporter
    attr_reader :survey, :include_partial_responses

    def initialize(survey, options = {})
      @survey = survey
      @include_partial_responses = options.fetch(:include_partial_responses, true)
      @responses = load_responses
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << generate_headers
        generate_rows.each { |row| csv << row }
      end
    end

    def generate_headers
      headers = [
        'Response ID',
        'Email',
        'Started At',
        'Completed At',
        'Completion %'
      ]
      
      # Add headers for each question
      all_questions.each do |question|
        if question.is_matrix_question
          # Skip matrix parent questions in headers
          next
        elsif question.matrix_parent_id
          # Matrix sub-questions get special headers
          parent = question.matrix_parent
          headers << "#{parent.title} - #{question.matrix_row_text}"
        else
          # Regular questions
          headers << "Q#{question.order_position}: #{question.title}"
        end
      end
      
      headers
    end

    def generate_rows
      @responses.map do |response|
        visibility_service = QuestionVisibilityService.new(response)
        
        row = [
          response.id,
          response.participant.email,
          response.created_at&.strftime('%Y-%m-%d %H:%M'),
          response.completed_at&.strftime('%Y-%m-%d %H:%M'),
          response.completion_percentage
        ]
        
        # Add answer data for each question
        all_questions.each do |question|
          if question.is_matrix_question
            # Skip matrix parent questions
            next
          elsif question.conditional_parent_id && !visibility_service.question_was_shown?(question)
            # Conditional question that wasn't shown - leave empty
            row << ''
          else
            row << get_answer_value(response, question)
          end
        end
        
        row
      end
    end

    private

    def load_responses
      scope = survey.responses.includes(
        :participant,
        answers: [:question, :options]
      )
      
      scope = scope.completed unless include_partial_responses
      scope
    end

    def all_questions
      @all_questions ||= survey.questions
        .includes(:question_type, :matrix_parent, :options)
        .ordered
    end

    def get_answer_value(response, question)
      answer = response.answers.find { |a| a.question_id == question.id }
      return '' unless answer

      case question.question_type.name
      when 'text', 'textarea', 'email'
        answer.text_answer
      when 'number', 'scale'
        answer.numeric_answer
      when 'boolean'
        answer.boolean_answer.nil? ? '' : (answer.boolean_answer ? 'Yes' : 'No')
      when 'single_choice', 'dropdown_single'
        answer.options.first&.option_text || ''
      when 'multiple_choice', 'dropdown_multiple'
        answer.options.map(&:option_text).join(', ')
      when 'matrix_scale'
        answer.options.first&.option_text || ''
      else
        answer.display_value
      end
    end
  end
end