module SurveyEngine
  class SurveysController < ApplicationController
    def index
      @surveys = Survey.all

      # Handle email resolution for completion status
      @current_email = resolve_participant_email

      # Get completion status for current user if email is available
      if @current_email.present?
        @completed_surveys = {}
        @surveys.each do |survey|
          participant = Participant.find_by(survey: survey, email: @current_email)
          @completed_surveys[survey.id] = participant&.completed? || false
        end
      end
    end

    def show
      # Preload associations to avoid N+1
      @survey = Survey.includes(
        :survey_template,
        questions: [
          :question_type, 
          :options,
          { matrix_sub_questions: [:question_type, :options] }
        ]
      ).find_by!(uuid: params[:id])
      
      @email = resolve_participant_email

      if @email.present?
        @participant = Participant.find_by(survey: @survey, email: @email)
        @response = @participant&.response if @participant

        if @participant&.completed?
          redirect_to completed_survey_path(@survey, email_params)
          return
        end
      end

      # Only show non-matrix-row questions in preview (matrix rows are shown under their parent)
      @questions = @survey.questions.select { |q| q.matrix_parent_id.nil? }.sort_by(&:order_position)
    end

    def answer
      # Preload all associations to avoid N+1 queries
      @survey = Survey.includes(
        :survey_template,
        questions: [
          :question_type, 
          :options, 
          :conditional_questions, 
          :conditional_parent, 
          { matrix_sub_questions: [:question_type, :options] }
        ]
      ).find_by!(uuid: params[:id])
      
      @email = resolve_participant_email

      if @email.blank?
        redirect_to survey_path(@survey), alert: t("survey_engine.flash.authentication_required")
        return
      end

      # Check if participant exists (invitation required)
      @participant = Participant.find_by(survey: @survey, email: @email)

      unless @participant
        redirect_to survey_path(@survey), alert: t("survey_engine.flash.not_invited")
        return
      end

      if @participant.completed?
        redirect_to completed_survey_path(@survey)
        return
      end

      # Create response if not exists
      @response = @participant.response || Response.create!(
        survey: @survey,
        participant: @participant
      )

      set_session_data(@email, @response.id)
      # Only show non-matrix-row questions in form (matrix rows are rendered by their parent)
      # Use already loaded questions to avoid additional queries
      @questions = @survey.questions.select { |q| q.matrix_parent_id.nil? }.sort_by(&:order_position)

      # Get existing answers
      @answers = {}
      @response.answers.includes(:options).each do |answer|
        @answers[answer.question_id] = answer
      end
    end

    def submit_answer
      @survey = Survey.find_by!(uuid: params[:id])
      @response = find_current_response

      errors = []
      saved_count = 0

      # Process all submitted answers
      if params[:answers].present?
        params[:answers].each do |question_id, answer_data|
          # SECURITY: Validate question belongs to current survey
          question = @survey.questions.find_by(id: question_id)
          unless question
            errors << "Invalid question ID: #{question_id}"
            next
          end

          # Skip if no data provided for this question
          next if answer_data.values.all?(&:blank?)

          # Find or create answer
          answer = Answer.find_or_initialize_by(
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
          when "text", "textarea", "email"
            answer.text_answer = answer_data["text_answer"] if answer_data["text_answer"].present?
          when "scale", "number"
            answer.numeric_answer = answer_data["numeric_answer"] if answer_data["numeric_answer"].present?
          when "boolean"
            answer.boolean_answer = answer_data["boolean_answer"] == "1" if answer_data["boolean_answer"].present?
          when "single_choice", "matrix_scale"
            if answer_data["option_id"].present?
              # SECURITY: Validate option belongs to current question or its matrix parent
              if question.matrix_parent_id.present?
                # For matrix rows, use parent question's options
                parent_question = question.matrix_parent
                option = parent_question.options.find_by(id: answer_data["option_id"])
                unless option
                  errors << "Invalid option ID: #{answer_data['option_id']} for matrix question #{question_id}"
                  next
                end
              else
                option = question.options.find_by(id: answer_data["option_id"])
                unless option
                  errors << "Invalid option ID: #{answer_data['option_id']} for question #{question_id}"
                  next
                end
              end
              
              # Always build the association for new records
              if answer.new_record?
                answer.answer_options.build(option: option)
              else
                # For existing records, save first then create association
                if answer.save
                  answer_option = AnswerOption.create(answer: answer, option: option)
                  unless answer_option.persisted?
                    errors << "#{question.title}: Failed to save answer option - #{answer_option.errors.full_messages.join(', ')}"
                    next
                  end
                else
                  errors << "#{question.title}: #{answer.errors.full_messages.join(', ')}"
                  next
                end
              end
              answer.other_text = answer_data["other_text"] if option.is_other? && answer_data["other_text"].present?
            end
          when "multiple_choice"
            if answer_data["option_ids"].present?
              answer_data["option_ids"].reject(&:blank?).each do |option_id|
                # SECURITY: Validate option belongs to current question
                option = question.options.find_by(id: option_id)
                unless option
                  errors << "Invalid option ID: #{option_id} for question #{question_id}"
                  next
                end
                
                if answer.new_record?
                  answer.answer_options.build(option: option)
                else
                  if answer.save # Save first if existing record
                    answer_option = AnswerOption.create(answer: answer, option: option)
                    unless answer_option.persisted?
                      errors << "#{question.title}: Failed to save answer option - #{answer_option.errors.full_messages.join(', ')}"
                      next
                    end
                  else
                    errors << "#{question.title}: #{answer.errors.full_messages.join(', ')}"
                    next
                  end
                end
              end
              answer.other_text = answer_data["other_text"] if answer_data["other_text"].present?
            end
          when "ranking"
            if answer_data["ranking"].present?
              ranking_errors = []
              valid_rankings = []
              
              # First, validate all rankings and collect valid ones
              answer_data["ranking"].each do |option_id, ranking_order|
                # SECURITY: Validate option belongs to current question
                option = question.options.find_by(id: option_id)
                unless option
                  ranking_errors << "Invalid option ID: #{option_id}"
                  next
                end
                
                valid_rankings << { option: option, ranking_order: ranking_order.to_i }
              end
              
              # If we have ranking errors, add them and skip
              if ranking_errors.any?
                errors << "#{question.title}: #{ranking_errors.uniq.join('; ')}"
                next
              end
              
              # Clear existing answer_options for ranking questions to avoid duplicates
              if answer.persisted?
                answer.answer_options.destroy_all
              end
              
              # Build all ranking options at once
              valid_rankings.each do |ranking_data|
                if answer.new_record?
                  answer.answer_options.build(
                    option: ranking_data[:option], 
                    ranking_order: ranking_data[:ranking_order]
                  )
                else
                  # For existing answers, create the options directly
                  answer_option = answer.answer_options.create(
                    option: ranking_data[:option], 
                    ranking_order: ranking_data[:ranking_order]
                  )
                  unless answer_option.persisted?
                    ranking_errors << "Failed to save ranking option: #{answer_option.errors.full_messages.join(', ')}"
                  end
                end
              end
              
              # Add consolidated error if any ranking errors occurred during creation
              if ranking_errors.any?
                errors << "#{question.title}: #{ranking_errors.uniq.join('; ')}"
                next
              end
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
          redirect_to answer_survey_path(@survey, email_params), alert: "#{t('survey_engine.flash.completion_errors')} #{errors.join('; ')}"
        else
          # Validate required fields for completion
          missing_required = validate_required_fields_for_completion(@survey, @response)

          if missing_required.any?
            error_message = "#{t('survey_engine.flash.missing_required')} #{missing_required.join(', ')}"
            redirect_to answer_survey_path(@survey, email_params), alert: error_message
          else
            # Complete the response and participant
            @response.complete!
            @response.participant.complete!

            clear_session_data

            redirect_to completed_survey_path(@survey, email_params)
          end
        end
      else
        # Just saving answers
        if errors.any?
          redirect_to answer_survey_path(@survey, email_params), alert: "#{t('survey_engine.flash.save_errors')} #{errors.join('; ')}"
        else
          answer_key = saved_count == 1 ? "survey_engine.flash.answers_saved" : "survey_engine.flash.answers_saved_plural"
          redirect_to answer_survey_path(@survey, email_params), notice: "#{saved_count} #{t(answer_key)}"
        end
      end
    end

    def completed
        @survey = Survey.includes(questions: :question_type).find_by!(uuid: params[:id])
      @email = resolve_participant_email
      @participant = Participant.find_by(survey: @survey, email: @email)
      
      if @participant
        @response = @participant.response
        # Preload answers with their associations to avoid N+1
        if @response
          @answers = @response.answers.includes(:question, :options).index_by(&:question_id)
        end
      end
    end

    def results
      @survey = Survey.find_by!(uuid: params[:id])
      @responses = @survey.responses.completed.includes(:participant, answers: [ :question, :options ])
      @questions = @survey.questions.ordered.includes(:question_type, :options)

      # Calculate general statistics
      @stats = {
        total_participants: @survey.participants.count,
        completed_responses: @responses.count,
        completion_rate: @survey.participants.any? ?
          (@responses.count.to_f / @survey.participants.count * 100).round(1) : 0,
        average_completion_time: calculate_average_completion_time(@responses)
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

    def resolve_participant_email
      begin
        instance_exec(&SurveyEngine.config.current_user_email_method)
      rescue => e
        Rails.logger.error "SurveyEngine: Error getting current user email: #{e.message}"
        nil
      end
    end

    def email_params
      {}
    end

    def set_session_data(email, response_id)
      session[:response_id] = response_id
    end

    def clear_session_data
      session.delete(:response_id)
      # Don't clear email in manual mode as it's used across surveys
    end

    def find_current_response
      if session[:response_id]
        Response.find(session[:response_id])
      else
        email = resolve_participant_email
        participant = Participant.find_by(survey: @survey, email: email)
        participant&.response
      end
    end

    def validate_required_fields_for_completion(survey, response)
      missing_required = []

      survey.questions.required.each do |question|
        # Skip matrix parent questions - they don't get answered directly
        if question.is_matrix?
          next
        end

        # Skip conditional questions that shouldn't be shown
        if question.is_conditional?
          parent_answer = response.answers.find_by(question: question.conditional_parent)
          if parent_answer.nil?
            # If parent not answered, skip this conditional question
            next
          end

          # Skip if conditional question shouldn't be shown
          # Pass the full Answer object to handle both scale and option conditionals
          next unless question.should_show?(parent_answer)
        end

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
      when "text", "textarea", "email"
        answer.text_answer.present?
      when "scale", "number"
        answer.numeric_answer.present?
      when "boolean"
        !answer.boolean_answer.nil?
      when "single_choice", "multiple_choice", "matrix_scale", "ranking"
        answer.answer_options.any?
      else
        false
      end
    end

    def calculate_average_completion_time(responses)
      return 0 if responses.empty?

      completion_times = responses.map(&:completion_time).compact
      return 0 if completion_times.empty?

      average_seconds = completion_times.sum / completion_times.count
      average_seconds.round(1)
    end

    def analyze_question_responses(question, responses)
      answers = responses.map { |r| r.answer_for_question(question) }.compact

      case question.question_type.name
      when "text", "textarea"
        {
          type: question.question_type.name,
          response_count: answers.count,
          responses: answers.map(&:text_answer).reject(&:blank?)
        }
      when "scale", "number"
        numeric_answers = answers.map(&:numeric_answer).compact
        {
          type: "numeric",
          response_count: numeric_answers.count,
          average: numeric_answers.any? ? (numeric_answers.sum.to_f / numeric_answers.count).round(2) : 0,
          min: numeric_answers.min || 0,
          max: numeric_answers.max || 0,
          distribution: numeric_answers.group_by(&:itself).transform_values(&:count)
        }
      when "boolean"
        boolean_answers = answers.map(&:boolean_answer).compact
        {
          type: "boolean",
          response_count: boolean_answers.count,
          yes_count: boolean_answers.count(true),
          no_count: boolean_answers.count(false),
          yes_percentage: boolean_answers.any? ? (boolean_answers.count(true).to_f / boolean_answers.count * 100).round(1) : 0
        }
      when "single_choice", "multiple_choice"
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
          type: "choice",
          response_count: answers.count,
          option_counts: option_counts,
          other_responses: other_responses
        }
      when "ranking"
        ranking_data = {}
        position_counts = {}

        answers.each do |answer|
          ranking_options = answer.answer_options.includes(:option).order(:ranking_order)
          ranking_options.each_with_index do |answer_option, index|
            option_text = answer_option.option.option_text
            position = index + 1
            
            ranking_data[option_text] ||= []
            ranking_data[option_text] << position
            
            position_counts[position] ||= {}
            position_counts[position][option_text] = (position_counts[position][option_text] || 0) + 1
          end
        end

        # Calculate average ranking positions
        average_rankings = {}
        ranking_data.each do |option_text, positions|
          average_rankings[option_text] = (positions.sum.to_f / positions.count).round(2)
        end

        {
          type: "ranking",
          response_count: answers.count,
          average_rankings: average_rankings.sort_by { |_, avg| avg },
          position_counts: position_counts,
          ranking_data: ranking_data
        }
      else
        { type: "unknown", response_count: 0 }
      end
    end

    def generate_csv_export
      CsvExporter.new(@survey, include_partial_responses: false).to_csv
    end

    def generate_json_export
      {
        survey: {
          id: @survey.id,
          title: @survey.title,
          template_name: @survey.survey_template&.name,
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
            completion_time: response.completion_time,
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
      when "text", "textarea"
        answer.text_answer
      when "scale", "number"
        answer.numeric_answer
      when "boolean"
        answer.boolean_answer ? "Yes" : "No"
      when "single_choice", "multiple_choice"
        option_texts = answer.options.map(&:option_text)
        result = option_texts.join(", ")
        result += " (Other: #{answer.other_text})" if answer.other_text.present?
        result
      when "ranking"
        answer.ranking_display_value
      else
        "Unknown"
      end
    end
  end
end
