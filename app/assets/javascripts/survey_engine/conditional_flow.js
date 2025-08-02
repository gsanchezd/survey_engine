/**
 * SurveyEngine Conditional Flow JavaScript
 * Handles dynamic show/hide of conditional questions based on parent question answers
 */

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
    element.classList.remove('conditional-hidden');
    element.classList.add('conditional-showing');
    element.style.display = 'block';
    
    // Re-enable form validation
    this.updateQuestionValidation(element, true);
    
    // Remove animation class after animation completes
    setTimeout(() => {
      element.classList.remove('conditional-showing');
    }, 500);
  }

  hideQuestion(element) {
    element.classList.add('conditional-hidden');
    element.classList.remove('conditional-showing');
    
    // Clear answers and disable validation
    this.clearQuestionAnswers(element);
    this.updateQuestionValidation(element, false);
    
    setTimeout(() => {
      if (element.classList.contains('conditional-hidden')) {
        element.style.display = 'none';
      }
    }, 500);
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
      return element && !element.classList.contains('conditional-hidden') && element.style.display !== 'none';
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
    const form = document.querySelector('.se-survey-form');
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