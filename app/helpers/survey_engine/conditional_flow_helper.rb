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
      
      {
        'data-conditional-parent' => question.conditional_parent_id.to_s,
        'data-conditional-operator' => question.conditional_operator,
        'data-conditional-value' => question.conditional_value.to_s,
        'data-show-if-met' => question.show_if_condition_met.to_s
      }
    end
    
    # Generate form input attributes for questions that can trigger conditionals
    def conditional_trigger_attributes(question, input_name)
      return {} unless question.has_conditional_questions?
      
      {
        'data-triggers-conditionals' => 'true',
        'data-question-id' => question.id.to_s,
        'data-input-name' => input_name,
        'onchange' => "SurveyConditionalFlow.handleInputChange(this)"
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
    def conditional_flow_config(survey)
      questions_data = survey.questions.includes(:conditional_parent, :conditional_questions).map do |question|
        {
          id: question.id,
          type: question.question_type.name,
          isConditional: question.is_conditional?,
          parentId: question.conditional_parent_id,
          operator: question.conditional_operator,
          value: question.conditional_value,
          showIfMet: question.show_if_condition_met,
          hasConditionals: question.has_conditional_questions?,
          childrenIds: question.conditional_questions.pluck(:id),
          required: question.is_required?
        }.compact
      end
      
      {
        surveyId: survey.id,
        questions: questions_data
      }.to_json.html_safe
    end
    
    # Helper to include conditional flow JavaScript
    # CSS is automatically included via asset pipeline (conditional_flow.css)
    # 
    # Options:
    # - inline: true (default) - Include JavaScript inline in the page
    # - inline: false - Use asset pipeline (requires javascript_include_tag 'survey_engine/conditional_flow')
    def conditional_flow_javascript_tag(inline: true)
      if inline
        content_tag(:script, raw(conditional_flow_javascript), type: 'text/javascript')
      else
        # Return instructions for asset pipeline usage
        content_tag(:noscript, 
          "<!-- Include via asset pipeline: javascript_include_tag 'survey_engine/conditional_flow' -->")
      end
    end
    
    # Initialize conditional flow JavaScript
    def initialize_conditional_flow(survey)
      javascript_tag do
        raw <<~JS
          document.addEventListener('DOMContentLoaded', function() {
            if (typeof SurveyConditionalFlow !== 'undefined') {
              const config = #{conditional_flow_config(survey)};
              const conditionalFlow = new SurveyConditionalFlow(config);
              conditionalFlow.initialize();
              
              // Make it globally accessible for debugging
              window.surveyConditionalFlow = conditionalFlow;
            } else {
              console.warn('SurveyConditionalFlow class not found. Make sure to include the conditional flow JavaScript.');
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
    
    
    def conditional_flow_javascript
      <<~JS
        class SurveyConditionalFlow {
          constructor(config = {}) {
            this.config = config;
            this.questions = new Map();
            this.conditionalQuestions = new Map();
            this.initialized = false;
          }

          initialize() {
            if (this.initialized) return;
            
            this.loadQuestions();
            this.bindEvents();
            this.evaluateInitialState();
            this.initialized = true;
            
            console.log('SurveyConditionalFlow initialized with', this.questions.size, 'questions');
          }

          loadQuestions() {
            // Load from config if available
            if (this.config.questions) {
              this.config.questions.forEach(questionData => {
                this.questions.set(questionData.id, questionData);
                
                if (questionData.isConditional) {
                  if (!this.conditionalQuestions.has(questionData.parentId)) {
                    this.conditionalQuestions.set(questionData.parentId, []);
                  }
                  this.conditionalQuestions.get(questionData.parentId).push(questionData);
                }
              });
            } else {
              // Fallback: load from DOM
              this.loadQuestionsFromDOM();
            }
          }

          loadQuestionsFromDOM() {
            document.querySelectorAll('[data-question-id]').forEach(questionEl => {
              const questionId = parseInt(questionEl.dataset.questionId);
              const parentId = questionEl.dataset.conditionalParent ? 
                parseInt(questionEl.dataset.conditionalParent) : null;
              
              const questionData = {
                id: questionId,
                element: questionEl,
                type: questionEl.dataset.questionType,
                parentId: parentId,
                operator: questionEl.dataset.conditionalOperator,
                value: parseFloat(questionEl.dataset.conditionalValue),
                showIfMet: questionEl.dataset.showIfMet === 'true',
                isConditional: parentId !== null,
                hasConditionals: questionEl.dataset.hasConditionals === 'true',
                childrenIds: questionEl.dataset.conditionalChildren ? 
                  questionEl.dataset.conditionalChildren.split(',').map(id => parseInt(id)) : []
              };

              this.questions.set(questionId, questionData);
              
              if (questionData.isConditional) {
                if (!this.conditionalQuestions.has(parentId)) {
                  this.conditionalQuestions.set(parentId, []);
                }
                this.conditionalQuestions.get(parentId).push(questionData);
              }
            });
          }

          bindEvents() {
            // Use event delegation for better performance
            document.addEventListener('change', this.handleInputChange.bind(this));
            document.addEventListener('input', this.handleInputChange.bind(this));
          }

          handleInputChange(event) {
            const input = event.target;
            
            // Check if this input can trigger conditionals
            if (!input.dataset.triggersConditionals) return;
            
            const questionId = parseInt(input.dataset.questionId);
            let selectedValue;
            
            if (input.type === 'radio' || input.type === 'range') {
              selectedValue = parseFloat(input.value);
            } else if (input.type === 'checkbox') {
              // Handle checkbox logic if needed
              return;
            } else {
              // Handle other input types
              selectedValue = input.value;
            }
            
            this.handleQuestionChange(questionId, selectedValue);
          }

          handleQuestionChange(parentQuestionId, selectedValue) {
            const childQuestions = this.conditionalQuestions.get(parentQuestionId);
            
            if (!childQuestions) return;

            childQuestions.forEach(childQuestion => {
              const shouldShow = this.evaluateCondition(
                selectedValue, 
                childQuestion.operator, 
                childQuestion.value,
                childQuestion.showIfMet
              );

              this.toggleQuestion(childQuestion, shouldShow);
            });

            this.updateProgress();
            this.updateFormValidation();
          }

          evaluateCondition(answerValue, operator, conditionalValue, showIfMet) {
            if (!operator || conditionalValue === undefined) return false;
            
            let conditionMet = false;

            switch (operator) {
              case 'less_than':
                conditionMet = answerValue < conditionalValue;
                break;
              case 'greater_than':
                conditionMet = answerValue > conditionalValue;
                break;
              case 'equal_to':
                conditionMet = answerValue === conditionalValue;
                break;
              case 'greater_than_or_equal':
                conditionMet = answerValue >= conditionalValue;
                break;
              case 'less_than_or_equal':
                conditionMet = answerValue <= conditionalValue;
                break;
              default:
                conditionMet = false;
            }

            return showIfMet ? conditionMet : !conditionMet;
          }

          toggleQuestion(questionData, shouldShow) {
            const element = this.getQuestionElement(questionData);
            if (!element) return;
            
            if (shouldShow) {
              this.showQuestion(element);
            } else {
              this.hideQuestion(element);
            }
          }

          showQuestion(element) {
            element.classList.remove('se-conditional-hidden');
            element.classList.add('se-conditional-showing');
            element.style.display = 'block';
            
            // Re-enable form validation
            this.updateQuestionValidation(element, true);
            
            // Update question numbers
            this.updateQuestionNumbers();
            
            // Remove animation class after animation completes
            setTimeout(() => {
              element.classList.remove('se-conditional-showing');
            }, 400);
          }

          hideQuestion(element) {
            element.classList.add('se-conditional-hidden');
            element.classList.remove('se-conditional-showing');
            
            // Clear answers and disable validation
            this.clearQuestionAnswers(element);
            this.updateQuestionValidation(element, false);
            
            // Update question numbers
            this.updateQuestionNumbers();
            
            setTimeout(() => {
              if (element.classList.contains('se-conditional-hidden')) {
                element.style.display = 'none';
              }
            }, 300);
          }

          clearQuestionAnswers(questionElement) {
            const inputs = questionElement.querySelectorAll('input, textarea, select');
            inputs.forEach(input => {
              if (input.type === 'radio' || input.type === 'checkbox') {
                input.checked = false;
              } else {
                input.value = '';
              }
              
              // Trigger change event to update any dependent logic
              input.dispatchEvent(new Event('change', { bubbles: true }));
            });
          }

          updateQuestionValidation(questionElement, isRequired) {
            const question = this.getQuestionFromElement(questionElement);
            if (!question || !question.required) return;
            
            const inputs = questionElement.querySelectorAll('input[required], textarea[required], select[required]');
            inputs.forEach(input => {
              if (isRequired) {
                input.setAttribute('required', 'required');
              } else {
                input.removeAttribute('required');
              }
            });
          }

          evaluateInitialState() {
            // Check for any pre-filled answers and evaluate conditions
            this.questions.forEach((questionData) => {
              if (!questionData.isConditional && questionData.hasConditionals) {
                const element = this.getQuestionElement(questionData);
                if (!element) return;
                
                const inputs = element.querySelectorAll('input[type="radio"]:checked, input[type="range"]');
                inputs.forEach(input => {
                  const selectedValue = parseFloat(input.value);
                  this.handleQuestionChange(questionData.id, selectedValue);
                });
              }
            });
            
            // Update question numbers after initial evaluation
            this.updateQuestionNumbers();
          }

          updateQuestionNumbers() {
            const visibleQuestions = document.querySelectorAll('.survey-question:not([style*="display: none"]):not(.se-conditional-hidden)');
            visibleQuestions.forEach((questionElement, index) => {
              const numberSpan = questionElement.querySelector('.survey-question-number');
              if (numberSpan) {
                numberSpan.textContent = index + 1;
              }
            });
          }

          updateProgress() {
            const visibleQuestions = this.getVisibleQuestions();
            const answeredQuestions = this.getAnsweredQuestions(visibleQuestions);
            
            const progressPercentage = visibleQuestions.length > 0 ? 
              Math.round((answeredQuestions.length / visibleQuestions.length) * 100) : 0;
            
            this.updateProgressDisplay(answeredQuestions.length, visibleQuestions.length, progressPercentage);
          }

          getVisibleQuestions() {
            return Array.from(this.questions.values()).filter(questionData => {
              const element = this.getQuestionElement(questionData);
              return element && !element.classList.contains('se-conditional-hidden') && element.style.display !== 'none';
            });
          }

          getAnsweredQuestions(visibleQuestions) {
            return visibleQuestions.filter(questionData => {
              const element = this.getQuestionElement(questionData);
              if (!element) return false;
              
              const inputs = element.querySelectorAll('input, textarea, select');
              return Array.from(inputs).some(input => {
                if (input.type === 'radio' || input.type === 'checkbox') {
                  return input.checked;
                }
                return input.value.trim() !== '';
              });
            });
          }

          updateProgressDisplay(answered, total, percentage) {
            const progressFill = document.querySelector('.se-progress-fill');
            const progressInfo = document.querySelector('.se-progress-info');
            
            if (progressFill) {
              progressFill.style.width = `${percentage}%`;
            }
            
            if (progressInfo) {
              progressInfo.innerHTML = `<strong>Progress:</strong> ${answered} of ${total} questions answered (${percentage}% complete)`;
            }
          }

          updateFormValidation() {
            // Update form validation state
            const form = document.querySelector('.survey-form');
            if (form && typeof form.checkValidity === 'function') {
              form.checkValidity();
            }
          }

          getQuestionElement(questionData) {
            if (questionData.element) {
              return questionData.element;
            }
            return document.getElementById(`question-${questionData.id}`);
          }

          getQuestionFromElement(element) {
            const questionId = parseInt(element.dataset.questionId);
            return this.questions.get(questionId);
          }

          // Static method for backwards compatibility
          static handleInputChange(input) {
            if (window.surveyConditionalFlow) {
              window.surveyConditionalFlow.handleInputChange({ target: input });
            }
          }

          // Debug helpers
          getDebugInfo() {
            return {
              totalQuestions: this.questions.size,
              conditionalQuestions: Array.from(this.conditionalQuestions.entries()),
              visibleQuestions: this.getVisibleQuestions().length,
              config: this.config
            };
          }
        }

        // Make globally available
        window.SurveyConditionalFlow = SurveyConditionalFlow;
      JS
    end
  end
end