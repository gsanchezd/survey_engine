//= require_tree .

/**
 * SurveyEngine Conditional Flow JavaScript
 * Handles dynamic show/hide of conditional questions based on parent question answers
 */

window.SurveyConditionalFlow = class {
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
        operator2: questionEl.dataset.conditionalOperator2,
        value2: questionEl.dataset.conditionalValue2 ? parseFloat(questionEl.dataset.conditionalValue2) : undefined,
        logicType: questionEl.dataset.conditionalLogicType || 'single',
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
      const shouldShow = this.evaluateComplexCondition(
        selectedValue, 
        childQuestion
      );

      this.toggleQuestion(childQuestion, shouldShow);
    });

    this.updateProgress();
    this.updateFormValidation();
  }

  evaluateComplexCondition(answerValue, questionData) {
    const { logicType, operator, value, operator2, value2, showIfMet } = questionData;
    
    let conditionMet = false;
    
    switch (logicType) {
      case 'and':
        conditionMet = this.evaluateSingleCondition(answerValue, operator, value) &&
                      this.evaluateSingleCondition(answerValue, operator2, value2);
        break;
      case 'or':
        conditionMet = this.evaluateSingleCondition(answerValue, operator, value) ||
                      this.evaluateSingleCondition(answerValue, operator2, value2);
        break;
      case 'range':
        // For range conditions, both conditions must be true (AND logic)
        conditionMet = this.evaluateSingleCondition(answerValue, operator, value) &&
                      this.evaluateSingleCondition(answerValue, operator2, value2);
        break;
      default:
        // Single condition logic
        conditionMet = this.evaluateSingleCondition(answerValue, operator, value);
    }
    
    return showIfMet ? conditionMet : !conditionMet;
  }

  evaluateSingleCondition(answerValue, operator, conditionalValue) {
    if (!operator || conditionalValue === undefined) return false;

    switch (operator) {
      case 'less_than':
        return answerValue < conditionalValue;
      case 'greater_than':
        return answerValue > conditionalValue;
      case 'equal_to':
        return answerValue === conditionalValue;
      case 'greater_than_or_equal':
        return answerValue >= conditionalValue;
      case 'less_than_or_equal':
        return answerValue <= conditionalValue;
      default:
        return false;
    }
  }

  // Keep the old method for backwards compatibility
  evaluateCondition(answerValue, operator, conditionalValue, showIfMet) {
    const conditionMet = this.evaluateSingleCondition(answerValue, operator, conditionalValue);
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
    // Add a slight delay before showing the question for better UX
    setTimeout(() => {
      element.classList.remove('conditional-hidden');
      element.classList.add('conditional-showing');
      element.style.display = 'block';
      
      // Re-enable form validation
      this.updateQuestionValidation(element, true);
      
      // Update question numbers
      this.updateQuestionNumbers();
      
      // Remove animation class after animation completes
      setTimeout(() => {
        element.classList.remove('conditional-showing');
      }, 400);
    }, 150);
  }

  hideQuestion(element) {
    // Hide the complete card instantly - no partial hiding
    element.classList.add('conditional-hidden');
    element.classList.remove('conditional-showing');
    element.style.display = 'none';
    
    // Clear answers and disable validation
    this.clearQuestionAnswers(element);
    this.updateQuestionValidation(element, false);
    
    // Update question numbers
    this.updateQuestionNumbers();
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

  updateQuestionNumbers() {
    // Get all questions
    const allQuestions = document.querySelectorAll('.survey-question');
    let questionNumber = 1;
    
    allQuestions.forEach((questionElement) => {
      // Skip if hidden by conditional logic (using the correct class name)
      const isHidden = questionElement.classList.contains('conditional-hidden') || 
                      questionElement.style.display === 'none';
      
      // Skip if it's a matrix row (rows don't get their own numbers)
      const isMatrixRow = questionElement.getAttribute('data-is-matrix-row') === 'true';
      
      if (!isHidden && !isMatrixRow) {
        const numberSpan = questionElement.querySelector('.survey-question-number');
        if (numberSpan) {
          numberSpan.textContent = questionNumber;
          questionNumber++;
        }
      }
    });
    
    // Also update any progress indicators that might show question count
    this.updateProgressWithNumbers(questionNumber - 1);
  }
  
  updateProgressWithNumbers(totalVisibleQuestions) {
    // Update any UI elements that show total question count
    const totalCountElements = document.querySelectorAll('[data-total-questions]');
    totalCountElements.forEach(element => {
      element.textContent = totalVisibleQuestions;
    });
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
};

// Matrix Question Interactions
document.addEventListener('DOMContentLoaded', function() {
  initializeMatrixQuestions();
});

function initializeMatrixQuestions() {
  const matrixQuestions = document.querySelectorAll('.matrix-question');
  
  matrixQuestions.forEach(function(matrixQuestion) {
    setupMatrixQuestion(matrixQuestion);
  });
}

function setupMatrixQuestion(matrixQuestion) {
  const radioButtons = matrixQuestion.querySelectorAll('.matrix-radio');
  const rows = matrixQuestion.querySelectorAll('.matrix-row');
  
  // Add change event listeners to radio buttons
  radioButtons.forEach(function(radio) {
    radio.addEventListener('change', function() {
      handleMatrixChange(this);
    });
    
    // Add focus/blur events for better accessibility
    radio.addEventListener('focus', function() {
      this.closest('.matrix-cell').classList.add('focused');
    });
    
    radio.addEventListener('blur', function() {
      this.closest('.matrix-cell').classList.remove('focused');
    });
  });
  
  // Add keyboard navigation
  matrixQuestion.addEventListener('keydown', function(e) {
    handleMatrixKeyboard(e);
  });
  
  // Initialize validation state for each row
  rows.forEach(function(row) {
    validateMatrixRow(row);
  });
  
  // Add visual feedback for interaction
  addMatrixInteractionFeedback(matrixQuestion);
}

function handleMatrixChange(radio) {
  const row = radio.closest('.matrix-row');
  const cell = radio.closest('.matrix-cell');
  const questionId = radio.dataset.questionId;
  const optionId = radio.dataset.optionId;
  
  // Clear previous selection styling in this row
  row.querySelectorAll('.matrix-cell').forEach(function(cell) {
    cell.classList.remove('selected');
  });
  
  // Add selection styling to current cell
  cell.classList.add('selected');
  
  // Update row validation state
  validateMatrixRow(row);
  
  // Trigger custom event for potential integrations
  const event = new CustomEvent('matrixAnswerChanged', {
    detail: {
      questionId: questionId,
      optionId: optionId,
      row: row,
      radio: radio
    }
  });
  document.dispatchEvent(event);
  
  // Optional: Auto-save functionality (if implemented)
  if (typeof autoSaveAnswer === 'function') {
    autoSaveAnswer(questionId, optionId);
  }
  
  // Add smooth visual feedback
  cell.style.transform = 'scale(1.05)';
  setTimeout(function() {
    cell.style.transform = '';
  }, 150);
}

function validateMatrixRow(row) {
  const radios = row.querySelectorAll('.matrix-radio');
  const isAnswered = Array.from(radios).some(radio => radio.checked);
  
  // Update row classes
  row.classList.toggle('answered', isAnswered);
  row.classList.toggle('unanswered', !isAnswered);
  
  return isAnswered;
}

function validateAllMatrixRows(matrixQuestion) {
  const rows = matrixQuestion.querySelectorAll('.matrix-row');
  let allAnswered = true;
  
  rows.forEach(function(row) {
    const isAnswered = validateMatrixRow(row);
    if (!isAnswered) {
      allAnswered = false;
    }
  });
  
  return allAnswered;
}

function handleMatrixKeyboard(e) {
  const target = e.target;
  
  // Only handle keyboard navigation for radio buttons
  if (!target.classList.contains('matrix-radio')) {
    return;
  }
  
  const currentCell = target.closest('.matrix-cell');
  const currentRow = target.closest('.matrix-row');
  const table = target.closest('.matrix-table');
  
  let newTarget = null;
  
  switch(e.key) {
    case 'ArrowUp':
      e.preventDefault();
      newTarget = findAdjacentRadio(table, currentRow, currentCell, 'up');
      break;
      
    case 'ArrowDown':
      e.preventDefault();
      newTarget = findAdjacentRadio(table, currentRow, currentCell, 'down');
      break;
      
    case 'ArrowLeft':
      e.preventDefault();
      newTarget = findAdjacentRadio(table, currentRow, currentCell, 'left');
      break;
      
    case 'ArrowRight':
      e.preventDefault();
      newTarget = findAdjacentRadio(table, currentRow, currentCell, 'right');
      break;
      
    case 'Space':
    case 'Enter':
      e.preventDefault();
      target.checked = true;
      handleMatrixChange(target);
      break;
  }
  
  if (newTarget) {
    newTarget.focus();
  }
}

function findAdjacentRadio(table, currentRow, currentCell, direction) {
  const allRows = Array.from(table.querySelectorAll('.matrix-row'));
  const cellsInRow = Array.from(currentRow.querySelectorAll('.matrix-cell'));
  
  const currentRowIndex = allRows.indexOf(currentRow);
  const currentCellIndex = cellsInRow.indexOf(currentCell);
  
  switch(direction) {
    case 'up':
      if (currentRowIndex > 0) {
        const prevRow = allRows[currentRowIndex - 1];
        const prevRowCells = prevRow.querySelectorAll('.matrix-cell');
        return prevRowCells[currentCellIndex]?.querySelector('.matrix-radio');
      }
      break;
      
    case 'down':
      if (currentRowIndex < allRows.length - 1) {
        const nextRow = allRows[currentRowIndex + 1];
        const nextRowCells = nextRow.querySelectorAll('.matrix-cell');
        return nextRowCells[currentCellIndex]?.querySelector('.matrix-radio');
      }
      break;
      
    case 'left':
      if (currentCellIndex > 0) {
        return cellsInRow[currentCellIndex - 1]?.querySelector('.matrix-radio');
      }
      break;
      
    case 'right':
      if (currentCellIndex < cellsInRow.length - 1) {
        return cellsInRow[currentCellIndex + 1]?.querySelector('.matrix-radio');
      }
      break;
  }
  
  return null;
}

function addMatrixInteractionFeedback(matrixQuestion) {
  const cells = matrixQuestion.querySelectorAll('.matrix-cell');
  
  cells.forEach(function(cell) {
    const radio = cell.querySelector('.matrix-radio');
    
    if (radio) {
      // Add click feedback
      cell.addEventListener('click', function(e) {
        // If clicking on the cell (not the radio), trigger the radio
        if (e.target === cell) {
          radio.checked = true;
          handleMatrixChange(radio);
        }
      });
      
      // Add hover effects
      cell.addEventListener('mouseenter', function() {
        if (!radio.checked) {
          cell.style.backgroundColor = '#f1f5f9';
        }
      });
      
      cell.addEventListener('mouseleave', function() {
        if (!radio.checked) {
          cell.style.backgroundColor = '';
        }
      });
    }
  });
}

// Utility function to get matrix completion status
function getMatrixCompletionStatus(matrixQuestion) {
  const rows = matrixQuestion.querySelectorAll('.matrix-row');
  let answered = 0;
  let total = rows.length;
  
  rows.forEach(function(row) {
    if (validateMatrixRow(row)) {
      answered++;
    }
  });
  
  return {
    answered: answered,
    total: total,
    percentage: total > 0 ? Math.round((answered / total) * 100) : 0,
    isComplete: answered === total
  };
}

// Export functions for potential external use
window.SurveyEngine = window.SurveyEngine || {};
window.SurveyEngine.Matrix = {
  validateAllMatrixRows: validateAllMatrixRows,
  getMatrixCompletionStatus: getMatrixCompletionStatus,
  initializeMatrixQuestions: initializeMatrixQuestions
};