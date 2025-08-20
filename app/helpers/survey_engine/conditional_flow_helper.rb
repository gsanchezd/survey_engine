module SurveyEngine
  module ConditionalFlowHelper
    
    # Main helper method to generate conditional flow data attributes for a question
    def conditional_flow_attributes(question)
      return {} unless question.is_a?(SurveyEngine::Question)
      
      attributes = {
        'data-question-id' => question.id.to_s,
        'data-question-type' => question.question_type.name,
        'data-is-conditional' => question.is_conditional?.to_s
      }
      
      if question.is_conditional?
        attributes.merge!(conditional_question_attributes(question))
        # Hide conditional questions by default
        attributes['style'] = 'display: none;'
      end
      
      if question.has_conditional_questions?
        attributes['data-has-conditionals'] = 'true'
        attributes['data-conditional-children'] = question.conditional_questions.pluck(:id).map(&:to_s).join(',')
      end
      
      attributes
    end
    
    # Generate data attributes specifically for conditional questions
    def conditional_question_attributes(question)
      return {} unless question.is_conditional?
      
      attributes = {
        'data-conditional-parent' => question.conditional_parent_id.to_s,
        'data-conditional-type' => question.conditional_type || 'scale',
        'data-conditional-logic-type' => question.conditional_logic_type || 'single',
        'data-show-if-met' => question.show_if_condition_met.to_s
      }
      
      if question.conditional_type == 'option'
        # For option-based conditionals, store the trigger option IDs
        trigger_option_ids = question.conditional_options.pluck(:id)
        attributes['data-conditional-option-ids'] = trigger_option_ids.join(',')
      else
        # For scale-based conditionals, store operator and value
        attributes.merge!({
          'data-conditional-operator' => question.conditional_operator,
          'data-conditional-value' => question.conditional_value.to_s
        })
        
        # Add second condition attributes for complex logic
        if question.conditional_logic_type.present? && question.conditional_logic_type != 'single'
          attributes.merge!({
            'data-conditional-operator2' => question.conditional_operator_2,
            'data-conditional-value2' => question.conditional_value_2.to_s
          })
        end
      end
      
      attributes
    end
    
    # Generate form input attributes for questions that can trigger conditionals
    def conditional_trigger_attributes(question, input_name)
      return {} unless question.has_conditional_questions?
      
      {
        'data-triggers-conditionals' => 'true',
        'data-question-id' => question.id.to_s,
        'data-input-name' => input_name
      }
    end
    
    # Helper to render a question with conditional flow support
    def conditional_question_container(question, options = {}, &block)
      default_classes = ['se-question-card']
      default_classes << 'se-conditional-question' if question.is_conditional?
      default_classes << options[:class] if options[:class]
      
      attributes = conditional_flow_attributes(question).merge(
        class: default_classes.join(' '),
        id: "question-#{question.id}"
      )
      
      # Merge any additional attributes
      attributes.merge!(options.except(:class))
      
      content_tag(:article, attributes, &block)
    end
    
    # Generate JavaScript configuration for the entire survey
    def conditional_flow_config(survey, questions = nil)
      questions_to_use = questions || survey.questions.includes(:conditional_parent, :conditional_questions, :conditional_options)
      questions_data = questions_to_use.map do |question|
        question_data = {
          id: question.id,
          type: question.question_type.name,
          isConditional: question.is_conditional?,
          parentId: question.conditional_parent_id,
          conditionalType: question.conditional_type || 'scale',
          logicType: question.conditional_logic_type || 'single',
          showIfMet: question.show_if_condition_met,
          hasConditionals: question.has_conditional_questions?,
          childrenIds: question.conditional_questions.pluck(:id),
          required: question.is_required?
        }
        
        if question.is_conditional?
          if question.conditional_type == 'option'
            question_data[:triggerOptionIds] = question.conditional_options.pluck(:id)
          else
            question_data.merge!({
              operator: question.conditional_operator,
              value: question.conditional_value&.to_i,
              operator2: question.conditional_operator_2,
              value2: question.conditional_value_2&.to_i
            })
          end
        end
        
        question_data.compact
      end
      
      {
        surveyId: survey.id,
        questions: questions_data
      }.to_json.html_safe
    end
    
    # Helper to include conditional flow JavaScript
    # 
    # DEPRECATED: This helper is no longer needed. Use the asset pipeline instead:
    # <%= javascript_include_tag "survey_engine/application" %>
    # 
    # This method is kept for backwards compatibility but will be removed in future versions.
    def conditional_flow_javascript_tag(inline: true)
      # JavaScript is included via asset pipeline in application.js
      content_tag(:noscript, 
        "<!-- SurveyConditionalFlow is included via asset pipeline -->")
    end
    
    # Initialize conditional flow JavaScript
    def initialize_conditional_flow(survey, questions = nil)
      javascript_tag do
        raw <<~JS
          document.addEventListener('DOMContentLoaded', function() {
            // Check if the class is available in the global scope (loaded via asset pipeline)
            if (typeof window.SurveyConditionalFlow !== 'undefined') {
              const config = #{conditional_flow_config(survey, questions)};
              const conditionalFlow = new window.SurveyConditionalFlow(config);
              conditionalFlow.initialize();
              
              // Make it globally accessible for debugging
              window.surveyConditionalFlow = conditionalFlow;
              
              console.log('SurveyConditionalFlow initialized successfully with', config.questions?.length || 0, 'questions');
            } else {
              console.warn('SurveyConditionalFlow class not found. Make sure survey_engine/application.js is included in your asset pipeline.');
              
              // Fallback: try to load questions from DOM
              if (typeof window.SurveyEngine !== 'undefined' && window.SurveyEngine.ConditionalFlow) {
                window.SurveyEngine.ConditionalFlow.initializeFromDOM();
              }
            }
          });
        JS
      end.html_safe
    end
    
    # Enhanced scale input helper with conditional flow support
    def conditional_scale_input(question, existing_answer = nil)
      return '' unless question.question_type.name == 'scale'
      
      content_tag(:div, class: 'se-scale-question', data: { question_type: 'scale' }) do
        scale_labels(question) + scale_options(question, existing_answer)
      end
    end
    
    private
    
    def scale_labels(question)
      content_tag(:div, class: 'se-scale-labels') do
        content_tag(:span, question.scale_min_label || question.scale_min, class: 'se-scale-min') +
        content_tag(:span, question.scale_max_label || question.scale_max, class: 'se-scale-max')
      end
    end
    
    def scale_options(question, existing_answer)
      content_tag(:div, class: 'se-scale-options') do
        (question.scale_min..question.scale_max).map do |value|
          scale_option(question, value, existing_answer)
        end.join.html_safe
      end
    end
    
    def scale_option(question, value, existing_answer)
      input_name = "answers[#{question.id}][numeric_answer]"
      input_id = "question_#{question.id}_value_#{value}"
      is_checked = existing_answer&.numeric_answer == value
      
      trigger_attrs = conditional_trigger_attributes(question, input_name)
      
      content_tag(:div, class: 'se-scale-option') do
        radio_button_tag(input_name, value, is_checked, 
          id: input_id,
          class: 'se-scale-input',
          **trigger_attrs
        ) +
        label_tag(input_id, value, class: 'se-scale-value')
      end
    end
    
  end
end