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
  end
end