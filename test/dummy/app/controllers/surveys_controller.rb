class SurveysController < ApplicationController
  def index
    @surveys = SurveyEngine::Survey.published.includes(:questions)
  end

  def show
    @survey = SurveyEngine::Survey.find(params[:id])
    @email = params[:email] || session[:email]
    
    if @email.present?
      @participant = SurveyEngine::Participant.find_by(survey: @survey, email: @email)
      @response = @participant&.response if @participant
      
      if @participant&.completed?
        redirect_to survey_completed_path(@survey, email: @email)
        return
      end
    end
    
    @questions = @survey.questions.ordered.includes(:question_type, :options)
  end

  def start
    @survey = SurveyEngine::Survey.find(params[:id])
    @email = params[:email]
    
    if @email.blank?
      redirect_to survey_path(@survey), alert: "Email is required"
      return
    end
    
    # Check if user already completed
    participant = SurveyEngine::Participant.find_by(survey: @survey, email: @email)
    if participant&.completed?
      redirect_to survey_completed_path(@survey, email: @email)
      return
    end
    
    # Create or find participant
    @participant = SurveyEngine::Participant.find_or_create_by(
      survey: @survey,
      email: @email
    ) do |p|
      p.status = 'invited'
    end
    
    # Create response if not exists
    @response = @participant.response || SurveyEngine::Response.create!(
      survey: @survey,
      participant: @participant
    )
    
    session[:email] = @email
    session[:response_id] = @response.id
    
    redirect_to answer_survey_path(@survey)
  end

  def answer
    @survey = SurveyEngine::Survey.find(params[:id])
    @response = SurveyEngine::Response.find(session[:response_id])
    @questions = @survey.questions.ordered.includes(:question_type, :options)
    
    # Get existing answers
    @answers = {}
    @response.answers.includes(:options).each do |answer|
      @answers[answer.question_id] = answer
    end
  end

  def submit_answer
    @survey = SurveyEngine::Survey.find(params[:id])
    @response = SurveyEngine::Response.find(session[:response_id])
    question = SurveyEngine::Question.find(params[:question_id])
    
    # Find or create answer
    answer = SurveyEngine::Answer.find_or_initialize_by(
      response: @response,
      question: question
    )
    
    # Clear existing data
    answer.text_answer = nil
    answer.numeric_answer = nil
    answer.decimal_answer = nil
    answer.boolean_answer = nil
    answer.other_text = nil
    answer.answer_options.destroy_all if answer.persisted?
    
    # Set answer based on question type
    case question.question_type.name
    when 'text'
      answer.text_answer = params[:text_answer]
    when 'scale', 'number'
      answer.numeric_answer = params[:numeric_answer]
    when 'boolean'
      answer.boolean_answer = params[:boolean_answer] == '1'
    when 'single_choice'
      if params[:option_id].present?
        option = SurveyEngine::Option.find(params[:option_id])
        if answer.new_record?
          answer.answer_options.build(option: option)
        else
          answer.save! # Save first if existing record
          SurveyEngine::AnswerOption.create!(answer: answer, option: option)
        end
        answer.other_text = params[:other_text] if option.is_other? && params[:other_text].present?
      end
    when 'multiple_choice'
      if params[:option_ids].present?
        params[:option_ids].each do |option_id|
          option = SurveyEngine::Option.find(option_id)
          if answer.new_record?
            answer.answer_options.build(option: option)
          else
            answer.save! # Save first if existing record
            SurveyEngine::AnswerOption.create!(answer: answer, option: option)
          end
        end
        answer.other_text = params[:other_text] if params[:other_text].present?
      end
    end
    
    if answer.save
      redirect_to answer_survey_path(@survey), notice: "Answer saved!"
    else
      redirect_to answer_survey_path(@survey), alert: "Error: #{answer.errors.full_messages.join(', ')}"
    end
  end

  def complete
    @survey = SurveyEngine::Survey.find(params[:id])
    @response = SurveyEngine::Response.find(session[:response_id])
    
    # Complete the response and participant
    @response.complete!
    @response.participant.complete!
    
    session.delete(:response_id)
    
    redirect_to survey_completed_path(@survey, email: @response.participant.email)
  end

  def completed
    @survey = SurveyEngine::Survey.find(params[:id])
    @email = params[:email]
    @participant = SurveyEngine::Participant.find_by(survey: @survey, email: @email)
    @response = @participant&.response
  end
end