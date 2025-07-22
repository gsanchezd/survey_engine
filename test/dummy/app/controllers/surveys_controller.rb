class SurveysController < ApplicationController
  def index
    @surveys = SurveyEngine::Survey.published.includes(:questions)
    
    # Set email from params or session
    if params[:email].present?
      session[:email] = params[:email]
      @current_email = params[:email]
    else
      @current_email = session[:email]
    end
    
    # Get completion status for current user if email is available
    if @current_email.present?
      @completed_surveys = {}
      @surveys.each do |survey|
        participant = SurveyEngine::Participant.find_by(survey: survey, email: @current_email)
        @completed_surveys[survey.id] = participant&.completed? || false
      end
    end
  end

  def show
    @survey = SurveyEngine::Survey.find(params[:id])
    @email = params[:email] || session[:email]
    
    if @email.present?
      @participant = SurveyEngine::Participant.find_by(survey: @survey, email: @email)
      @response = @participant&.response if @participant
      
      if @participant&.completed?
        redirect_to completed_survey_path(@survey, email: @email)
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
      redirect_to completed_survey_path(@survey, email: @email)
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
    
    errors = []
    saved_count = 0
    
    # Process all submitted answers
    if params[:answers].present?
      params[:answers].each do |question_id, answer_data|
        question = SurveyEngine::Question.find(question_id)
        
        # Skip if no data provided for this question
        next if answer_data.values.all?(&:blank?)
        
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
          answer.text_answer = answer_data[:text_answer] if answer_data[:text_answer].present?
        when 'scale', 'number'
          answer.numeric_answer = answer_data[:numeric_answer] if answer_data[:numeric_answer].present?
        when 'boolean'
          answer.boolean_answer = answer_data[:boolean_answer] == '1' if answer_data[:boolean_answer].present?
        when 'single_choice'
          if answer_data[:option_id].present?
            option = SurveyEngine::Option.find(answer_data[:option_id])
            if answer.new_record?
              answer.answer_options.build(option: option)
            else
              answer.save! # Save first if existing record
              SurveyEngine::AnswerOption.create!(answer: answer, option: option)
            end
            answer.other_text = answer_data[:other_text] if option.is_other? && answer_data[:other_text].present?
          end
        when 'multiple_choice'
          if answer_data[:option_ids].present?
            answer_data[:option_ids].reject(&:blank?).each do |option_id|
              option = SurveyEngine::Option.find(option_id)
              if answer.new_record?
                answer.answer_options.build(option: option)
              else
                answer.save! # Save first if existing record
                SurveyEngine::AnswerOption.create!(answer: answer, option: option)
              end
            end
            answer.other_text = answer_data[:other_text] if answer_data[:other_text].present?
          end
        end
        
        if answer.save
          saved_count += 1
        else
          errors << "#{question.title}: #{answer.errors.full_messages.join(', ')}"
        end
      end
    end
    
    # Check if this is a completion request
    if params[:complete_survey].present?
      if errors.any?
        redirect_to answer_survey_path(@survey), alert: "Cannot complete survey due to errors: #{errors.join('; ')}"
      else
        # Validate required fields for completion
        missing_required = validate_required_fields_for_completion(@survey, @response)
        
        if missing_required.any?
          error_message = "Please answer these required questions before completing: #{missing_required.join(', ')}"
          redirect_to answer_survey_path(@survey), alert: error_message
        else
          # Complete the response and participant
          @response.complete!
          @response.participant.complete!
          
          session.delete(:response_id)
          
          redirect_to completed_survey_path(@survey, email: @response.participant.email)
        end
      end
    else
      # Just saving answers (though this path won't be used with the new UI)
      if errors.any?
        redirect_to answer_survey_path(@survey), alert: "Some answers couldn't be saved: #{errors.join('; ')}"
      else
        redirect_to answer_survey_path(@survey), notice: "#{saved_count} answer#{'s' if saved_count != 1} saved successfully!"
      end
    end
  end


  def completed
    @survey = SurveyEngine::Survey.find(params[:id])
    @email = params[:email]
    @participant = SurveyEngine::Participant.find_by(survey: @survey, email: @email)
    @response = @participant&.response
  end

  private

  def validate_required_fields_for_completion(survey, response)
    missing_required = []
    
    survey.questions.required.each do |question|
      answer = response.answers.find_by(question: question)
      
      # Check if answer exists and has content
      if answer.nil? || !answer_has_content?(answer)
        missing_required << question.title
      end
    end
    
    missing_required
  end

  def answer_has_content?(answer)
    return false if answer.nil?
    
    case answer.question.question_type.name
    when 'text'
      answer.text_answer.present?
    when 'scale', 'number'
      answer.numeric_answer.present?
    when 'boolean'
      !answer.boolean_answer.nil?
    when 'single_choice', 'multiple_choice'
      answer.answer_options.any?
    else
      false
    end
  end
end