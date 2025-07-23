module SurveyEngine
  class SurveysController < ApplicationController
    def index
      @surveys = Survey.published.active
    end

    def show
      @survey = Survey.find_by!(uuid: params[:id])
      redirect_to root_path unless @survey.can_receive_responses?
      @questions = @survey.questions.includes(:question_type, :options).order(:order_position)
    end

    def start
      @survey = Survey.find_by!(uuid: params[:id])
      redirect_to root_path unless @survey.can_receive_responses?
      
      email = params[:email]
      
      # Check if participant already exists
      @participant = Participant.find_by(survey: @survey, email: email)
      
      if @participant&.completed?
        redirect_to survey_path(@survey), alert: "You have already completed this survey."
        return
      end
      
      # Create or find participant
      @participant = Participant.find_or_create_by(survey: @survey, email: email) do |p|
        p.status = 'invited'
      end
      
      # Create response
      @response = Response.find_or_create_by(survey: @survey, participant: @participant)
      
      # Redirect to answer page
      redirect_to answer_survey_path(@survey, email: email)
    end

    def answer
      @survey = Survey.find_by!(uuid: params[:id])
      @questions = @survey.questions.includes(:question_type, :options).order(:order_position)
      
      email = params[:email]
      @participant = Participant.find_by(survey: @survey, email: email)
      @response = Response.find_by(survey: @survey, participant: @participant)
      
      redirect_to survey_path(@survey), alert: "Survey session not found" unless @response
      
      # Load existing answers indexed by question_id
      @answers = @response.answers.includes(:options).index_by(&:question_id)
      @email = email
    end

    def submit_answer
      @survey = Survey.find_by!(uuid: params[:id])
      email = params[:email]
      @participant = Participant.find_by(survey: @survey, email: email)
      @response = Response.find_by(survey: @survey, participant: @participant)
      
      redirect_to survey_path(@survey), alert: "Survey session not found" and return unless @response
      
      # Process answers for each question
      params[:answers]&.each do |question_id, answer_data|
        question = Question.find(question_id)
        next unless question.survey == @survey
        
        # Find or create answer
        answer = Answer.find_or_initialize_by(response: @response, question: question)
        
        case question.question_type.name
        when 'text'
          answer.text_answer = answer_data[:text_answer]
        when 'scale', 'number'
          answer.numeric_answer = answer_data[:numeric_answer]
        when 'boolean'
          answer.boolean_answer = answer_data[:boolean_answer]
        when 'single_choice'
          answer.answer_options.destroy_all
          if answer_data[:option_id].present?
            option = Option.find(answer_data[:option_id])
            answer.answer_options.build(option: option)
            answer.other_text = answer_data[:other_text] if option.is_other?
          end
        when 'multiple_choice'
          answer.answer_options.destroy_all
          if answer_data[:option_ids].present?
            answer_data[:option_ids].each do |option_id|
              next if option_id.blank?
              option = Option.find(option_id)
              answer.answer_options.build(option: option)
            end
            answer.other_text = answer_data[:other_text]
          end
        end
        
        answer.save!
      end
      
      # Mark response and participant as completed
      @response.update!(completed_at: Time.current)
      @participant.update!(status: 'completed', completed_at: Time.current)
      
      redirect_to completed_survey_path(@survey, email: email)
    end

    def completed
      @survey = Survey.find_by!(uuid: params[:id])
      @email = params[:email]
      @participant = Participant.find_by(survey: @survey, email: @email)
      
      redirect_to survey_path(@survey), alert: "Survey not completed" unless @participant&.completed?
    end

    def results
      @survey = Survey.find_by!(uuid: params[:id])
      @responses = @survey.responses.where.not(completed_at: nil).includes(:participant, answers: [:question, :options])
      @questions = @survey.questions.order(:order_position).includes(:question_type, :options)
      
      # Calculate general statistics
      @stats = {
        total_participants: @survey.participants.count,
        completed_responses: @responses.count,
        completion_rate: @survey.participants.any? ? 
          (@responses.count.to_f / @survey.participants.count * 100).round(1) : 0
      }
      
      # Calculate question-specific analytics
      @question_analytics = {}
      @questions.each do |question|
        @question_analytics[question.id] = analyze_question_responses(question, @responses)
      end
      
      # Handle export formats
      respond_to do |format|
        format.html # Default view
        format.csv { send_data generate_csv_export, filename: "survey_#{@survey.id}_results.csv" }
        format.json { render json: generate_json_export }
      end
    end

    private

    def analyze_question_responses(question, responses)
      answers = responses.map { |r| r.answer_for_question(question) }.compact
      
      case question.question_type.name
      when 'text'
        {
          type: 'text',
          response_count: answers.count,
          responses: answers.map(&:text_answer).reject(&:blank?)
        }
      when 'scale', 'number'
        numeric_answers = answers.map(&:numeric_answer).compact
        {
          type: 'numeric',
          response_count: numeric_answers.count,
          average: numeric_answers.any? ? (numeric_answers.sum.to_f / numeric_answers.count).round(2) : 0,
          min: numeric_answers.min || 0,
          max: numeric_answers.max || 0,
          distribution: numeric_answers.group_by(&:itself).transform_values(&:count)
        }
      when 'boolean'
        boolean_answers = answers.map(&:boolean_answer).compact
        {
          type: 'boolean',
          response_count: boolean_answers.count,
          yes_count: boolean_answers.count(true),
          no_count: boolean_answers.count(false),
          yes_percentage: boolean_answers.any? ? (boolean_answers.count(true).to_f / boolean_answers.count * 100).round(1) : 0
        }
      when 'single_choice', 'multiple_choice'
        option_counts = {}
        other_responses = []
        
        answers.each do |answer|
          answer.options.each do |option|
            option_counts[option.option_text] = (option_counts[option.option_text] || 0) + 1
            if option.is_other? && answer.other_text.present?
              other_responses << answer.other_text
            end
          end
        end
        
        {
          type: 'choice',
          response_count: answers.count,
          option_counts: option_counts,
          other_responses: other_responses
        }
      else
        { type: 'unknown', response_count: 0 }
      end
    end

    def generate_csv_export
      require 'csv'
      
      CSV.generate do |csv|
        # Header row
        headers = ['Participant Email', 'Completed At']
        @questions.each { |q| headers << q.title }
        csv << headers
        
        # Data rows
        @responses.each do |response|
          row = [
            response.participant.email,
            response.completed_at&.strftime("%Y-%m-%d %H:%M:%S")
          ]
          
          @questions.each do |question|
            answer = response.answer_for_question(question)
            row << (answer ? format_answer_for_export(answer) : "")
          end
          
          csv << row
        end
      end
    end

    def generate_json_export
      {
        survey: {
          id: @survey.id,
          title: @survey.title,
          description: @survey.description,
          created_at: @survey.created_at
        },
        statistics: @stats,
        questions: @questions.map do |question|
          {
            id: question.id,
            title: question.title,
            type: question.question_type.name,
            analytics: @question_analytics[question.id]
          }
        end,
        responses: @responses.map do |response|
          {
            participant_email: response.participant.email,
            completed_at: response.completed_at,
            answers: @questions.map do |question|
              answer = response.answer_for_question(question)
              {
                question_id: question.id,
                question_title: question.title,
                value: answer ? format_answer_for_export(answer) : nil
              }
            end
          }
        end
      }
    end

    def format_answer_for_export(answer)
      case answer.question.question_type.name
      when 'text'
        answer.text_answer
      when 'scale', 'number'
        answer.numeric_answer
      when 'boolean'
        answer.boolean_answer ? 'Yes' : 'No'
      when 'single_choice', 'multiple_choice'
        option_texts = answer.options.map(&:option_text)
        result = option_texts.join(', ')
        result += " (Other: #{answer.other_text})" if answer.other_text.present?
        result
      else
        'Unknown'
      end
    end
  end
end
