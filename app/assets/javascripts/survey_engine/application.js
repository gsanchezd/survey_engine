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
        conditionalType: questionEl.dataset.conditionalType || 'scale',
        operator: questionEl.dataset.conditionalOperator,
        value: parseFloat(questionEl.dataset.conditionalValue),
        operator2: questionEl.dataset.conditionalOperator2,
        value2: questionEl.dataset.conditionalValue2 ? parseFloat(questionEl.dataset.conditionalValue2) : undefined,
        triggerOptionIds: questionEl.dataset.conditionalOptionIds ? 
          questionEl.dataset.conditionalOptionIds.split(',').map(id => parseInt(id)) : [],
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
    if (!input.dataset.triggersConditionals) {
      return;
    }
    
    const questionId = parseInt(input.dataset.questionId);
    
    // Handle different input types
    if (input.type === 'radio' && input.name.includes('numeric_answer')) {
      // Scale questions - pass numeric value
      const selectedValue = parseFloat(input.value);
      this.handleQuestionChange(questionId, selectedValue, 'scale');
    } else if (input.type === 'radio' && input.name.includes('option_id')) {
      // Single choice questions - pass selected option ID
      const selectedOptionId = parseInt(input.value);
      this.handleQuestionChange(questionId, selectedOptionId, 'option');
    } else if (input.type === 'checkbox' && input.name.includes('option_ids')) {
      // Multiple choice questions - pass all selected option IDs
      const selectedOptionIds = this.getSelectedOptionIds(questionId);
      this.handleQuestionChange(questionId, selectedOptionIds, 'option');
    } else {
      // Other input types (text, etc.) - for scale-based conditionals
      const selectedValue = input.value;
      this.handleQuestionChange(questionId, selectedValue, 'scale');
    }
  }

  getSelectedOptionIds(questionId) {
    const checkboxes = document.querySelectorAll(`input[type="checkbox"][name*="[${questionId}]"][name*="option_ids"]:checked`);
    return Array.from(checkboxes).map(checkbox => parseInt(checkbox.value));
  }

  handleQuestionChange(parentQuestionId, selectedValue, answerType = 'scale') {
    const childQuestions = this.conditionalQuestions.get(parentQuestionId);
    
    if (!childQuestions) {
      return;
    }

    childQuestions.forEach(childQuestion => {
      const shouldShow = this.evaluateComplexCondition(
        selectedValue, 
        childQuestion,
        answerType
      );

      this.toggleQuestion(childQuestion, shouldShow);
    });

    this.updateProgress();
    this.updateFormValidation();
  }

  evaluateComplexCondition(answerValue, questionData, answerType = 'scale') {
    const { conditionalType, logicType, operator, value, operator2, value2, showIfMet, triggerOptionIds } = questionData;
    
    let conditionMet = false;
    
    // Handle option-based conditionals
    if (conditionalType === 'option') {
      conditionMet = this.evaluateOptionCondition(answerValue, triggerOptionIds, answerType);
    } else {
      // Handle scale-based conditionals (existing logic)
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
    }
    
    return showIfMet ? conditionMet : !conditionMet;
  }

  evaluateOptionCondition(answerValue, triggerOptionIds, answerType) {
    if (!triggerOptionIds || triggerOptionIds.length === 0) {
      return false;
    }
    
    if (answerType === 'option') {
      // For single choice: answerValue is a single option ID
      // For multiple choice: answerValue is an array of option IDs
      const selectedIds = Array.isArray(answerValue) ? answerValue : [answerValue];
      
      // Return true if any of the selected options matches any trigger option (OR logic)
      return selectedIds.some(selectedId => triggerOptionIds.includes(selectedId));
    }
    
    return false;
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
        
        // Handle scale-based triggers
        const scaleInputs = element.querySelectorAll('input[type="radio"][name*="numeric_answer"]:checked, input[type="range"]');
        scaleInputs.forEach(input => {
          const selectedValue = parseFloat(input.value);
          this.handleQuestionChange(questionData.id, selectedValue, 'scale');
        });
        
        // Handle option-based triggers (single choice)
        const singleChoiceInputs = element.querySelectorAll('input[type="radio"][name*="option_id"]:checked');
        singleChoiceInputs.forEach(input => {
          const selectedOptionId = parseInt(input.value);
          this.handleQuestionChange(questionData.id, selectedOptionId, 'option');
        });
        
        // Handle option-based triggers (multiple choice)
        const multipleChoiceInputs = element.querySelectorAll('input[type="checkbox"][name*="option_ids"]:checked');
        if (multipleChoiceInputs.length > 0) {
          const selectedOptionIds = Array.from(multipleChoiceInputs).map(input => parseInt(input.value));
          this.handleQuestionChange(questionData.id, selectedOptionIds, 'option');
        }
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

// Ranking Question Functionality
document.addEventListener('DOMContentLoaded', function() {
  initializeRankingQuestions();
});

function initializeRankingQuestions() {
  const rankingContainers = document.querySelectorAll('.survey-ranking-container');
  
  rankingContainers.forEach(function(container) {
    setupRankingQuestion(container);
  });
}

function setupRankingQuestion(container) {
  const questionId = container.dataset.questionId;
  const availableList = container.querySelector(`#available-options-${questionId}`);
  const rankedList = container.querySelector(`#ranked-options-${questionId}`);
  const inputsContainer = container.querySelector(`#ranking-inputs-${questionId}`);
  
  // Enable drag and drop for both lists
  enableDragAndDrop(availableList, rankedList, inputsContainer, questionId);
  enableDragAndDrop(rankedList, availableList, inputsContainer, questionId);
  
  // Enable touch support for mobile devices
  enableTouchSupport(availableList, rankedList, inputsContainer, questionId);
  enableTouchSupport(rankedList, availableList, inputsContainer, questionId);
  
  // Initialize ranking numbers if there are already ranked items
  updateRankingNumbers(rankedList);
  
  // Add helpful instructions
  addRankingInstructions(container);
}

function enableDragAndDrop(sourceList, targetList, inputsContainer, questionId) {
  const items = sourceList.querySelectorAll('.survey-ranking-item');
  
  items.forEach(function(item) {
    setupDragForItem(item, inputsContainer, questionId);
  });
  
  // Handle drop events on lists with enhanced visual feedback
  [sourceList, targetList].forEach(function(list) {
    setupEnhancedDropZone(list, inputsContainer, questionId);
  });
}

function setupEnhancedDropZone(list, inputsContainer, questionId) {
  let dragOverTimeout;
  let dropIndicator = null;
  
  list.addEventListener('dragover', function(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    
    // Clear any existing timeout
    clearTimeout(dragOverTimeout);
    
    // Add visual feedback
    list.classList.add('drag-over');
    
    // Get the position where the item would be inserted
    const afterElement = getDragAfterElement(list, e.clientY);
    const dropPosition = getDropPosition(list, afterElement);
    
    // Show drop indicator
    showDropIndicator(list, dropPosition, afterElement);
  });
  
  list.addEventListener('dragleave', function(e) {
    // Only remove visual feedback if we're truly leaving the container
    dragOverTimeout = setTimeout(function() {
      list.classList.remove('drag-over');
      removeDropIndicator(list);
    }, 50);
  });
  
  list.addEventListener('drop', function(e) {
    e.preventDefault();
    clearTimeout(dragOverTimeout);
    list.classList.remove('drag-over');
    removeDropIndicator(list);
    
    const data = JSON.parse(e.dataTransfer.getData('text/plain'));
    const draggedItem = document.querySelector(`[data-option-id="${data.optionId}"]`);
    
    if (draggedItem) {
      const afterElement = getDragAfterElement(list, e.clientY);
      moveRankingItemToPosition(draggedItem, list, afterElement, inputsContainer, questionId);
    }
  });
}

function getDragAfterElement(container, y) {
  const draggableElements = [...container.querySelectorAll('.survey-ranking-item:not(.dragging)')];
  
  return draggableElements.reduce((closest, child) => {
    const box = child.getBoundingClientRect();
    const offset = y - box.top - box.height / 2;
    
    if (offset < 0 && offset > closest.offset) {
      return { offset: offset, element: child };
    } else {
      return closest;
    }
  }, { offset: Number.NEGATIVE_INFINITY }).element;
}

function getDropPosition(list, afterElement) {
  if (!afterElement) {
    return 'end'; // Insert at the end
  }
  return 'before'; // Insert before the afterElement
}

function showDropIndicator(list, position, afterElement) {
  // Remove any existing indicator
  removeDropIndicator(list);
  
  // Create drop indicator
  const indicator = document.createElement('div');
  indicator.className = 'ranking-drop-indicator';
  indicator.innerHTML = '<div class="drop-line"></div><div class="drop-arrow">▼</div>';
  
  // Position the indicator
  if (position === 'end' || !afterElement) {
    list.appendChild(indicator);
  } else {
    list.insertBefore(indicator, afterElement);
  }
}

function removeDropIndicator(list) {
  const indicator = list.querySelector('.ranking-drop-indicator');
  if (indicator) {
    indicator.remove();
  }
}

function moveRankingItemToPosition(item, targetList, afterElement, inputsContainer, questionId) {
  // Add smooth transition effect
  item.style.transition = 'all 0.3s ease';
  
  // Remove from current position
  item.remove();
  
  // Insert at the correct position
  if (!afterElement) {
    targetList.appendChild(item);
  } else {
    targetList.insertBefore(item, afterElement);
  }
  
  // Add insertion animation
  item.classList.add('just-moved');
  setTimeout(function() {
    item.classList.remove('just-moved');
    item.style.transition = '';
  }, 300);
  
  // Re-enable drag and drop for the moved item
  setupDragForItem(item, inputsContainer, questionId);
  
  // Update hidden inputs and numbering
  updateRankingInputs(targetList, inputsContainer, questionId);
  updateRankingNumbers(targetList);
  
  // Update empty states for both lists
  const container = targetList.closest('.survey-ranking-container');
  const availableList = container.querySelector('.survey-ranking-available .survey-ranking-list');
  const rankedList = container.querySelector('.survey-ranking-ranked .survey-ranking-list');
  updateEmptyStates(availableList, rankedList);
}

function moveRankingItem(item, targetList, inputsContainer, questionId) {
  const optionId = item.dataset.optionId;
  
  // Remove from current position
  item.remove();
  
  // Add to target list
  targetList.appendChild(item);
  
  // Re-enable drag and drop for the moved item
  setupDragForItem(item, inputsContainer, questionId);
  
  // Update hidden inputs
  updateRankingInputs(targetList, inputsContainer, questionId);
}

function setupDragForItem(item, inputsContainer, questionId) {
  // Enhanced drag start with better visual feedback
  item.addEventListener('dragstart', function(e) {
    e.dataTransfer.setData('text/plain', JSON.stringify({
      optionId: item.dataset.optionId,
      optionText: item.textContent.trim()
    }));
    
    // Add dragging class with delay to allow for grab effect
    setTimeout(function() {
      item.classList.add('dragging');
    }, 0);
    
    // Set drag image to be slightly transparent
    e.dataTransfer.effectAllowed = 'move';
  });
  
  item.addEventListener('dragend', function(e) {
    item.classList.remove('dragging');
    
    // Clean up any remaining visual states
    document.querySelectorAll('.ranking-drop-indicator').forEach(function(indicator) {
      indicator.remove();
    });
    document.querySelectorAll('.drag-over').forEach(function(element) {
      element.classList.remove('drag-over');
    });
  });
  
  // Add hover effects for better UX
  item.addEventListener('mouseenter', function() {
    item.classList.add('hover');
  });
  
  item.addEventListener('mouseleave', function() {
    item.classList.remove('hover');
  });
}

function updateRankingNumbers(rankedList) {
  const rankedItems = rankedList.querySelectorAll('.survey-ranking-item');
  rankedItems.forEach(function(item, index) {
    // Add or update ranking number
    let numberElement = item.querySelector('.ranking-number');
    if (!numberElement) {
      numberElement = document.createElement('span');
      numberElement.className = 'ranking-number';
      item.insertBefore(numberElement, item.firstChild);
    }
    numberElement.textContent = (index + 1) + '.';
  });
}

function updateRankingInputs(rankedList, inputsContainer, questionId) {
  // Clear existing inputs
  inputsContainer.innerHTML = '';
  
  // Create new inputs based on current ranking order
  const rankedItems = rankedList.querySelectorAll('.survey-ranking-item');
  rankedItems.forEach(function(item, index) {
    const optionId = item.dataset.optionId;
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = `answers[${questionId}][ranking][${optionId}]`;
    input.value = index + 1;
    inputsContainer.appendChild(input);
  });
}

// Add click-to-move functionality for mobile/accessibility
function addClickToMoveRanking() {
  const rankingItems = document.querySelectorAll('.survey-ranking-item');
  
  rankingItems.forEach(function(item) {
    item.addEventListener('click', function(e) {
      if (item.classList.contains('selected-for-move')) {
        item.classList.remove('selected-for-move');
      } else {
        // Clear other selections
        document.querySelectorAll('.survey-ranking-item.selected-for-move')
          .forEach(function(selected) {
            selected.classList.remove('selected-for-move');
          });
        
        item.classList.add('selected-for-move');
      }
    });
  });
}

function addRankingInstructions(container) {
  // Add enhanced visual feedback and instructions
  const availableList = container.querySelector('.survey-ranking-available .survey-ranking-list');
  const rankedList = container.querySelector('.survey-ranking-ranked .survey-ranking-list');
  
  // Get i18n translations from data attributes
  const i18nAvailable = container.dataset.i18nAvailable || 'Available options';
  const i18nRanking = container.dataset.i18nRanking || 'Your ranking';
  const i18nDragToRank = container.dataset.i18nDragToRank || 'Drag to "Your ranking"';
  const i18nDragHere = container.dataset.i18nDragHere || 'Drag here to order';
  
  // Add visual feedback for empty states
  if (!availableList.querySelector('.empty-state-message')) {
    const availableEmptyMessage = document.createElement('div');
    availableEmptyMessage.className = 'empty-state-message';
    availableEmptyMessage.innerHTML = i18nAvailable + '<br><small>' + i18nDragToRank + '</small>';
    availableList.appendChild(availableEmptyMessage);
  }
  
  if (!rankedList.querySelector('.empty-state-message')) {
    const rankedEmptyMessage = document.createElement('div');
    rankedEmptyMessage.className = 'empty-state-message';
    rankedEmptyMessage.innerHTML = i18nRanking + '<br><small>' + i18nDragHere + '</small>';
    rankedList.appendChild(rankedEmptyMessage);
  }
  
  // Update empty state visibility
  updateEmptyStates(availableList, rankedList);
}

function updateEmptyStates(availableList, rankedList) {
  const availableMessage = availableList.querySelector('.empty-state-message');
  const rankedMessage = rankedList.querySelector('.empty-state-message');
  const availableItems = availableList.querySelectorAll('.survey-ranking-item');
  const rankedItems = rankedList.querySelectorAll('.survey-ranking-item');
  
  if (availableMessage) {
    availableMessage.style.display = availableItems.length === 0 ? 'block' : 'none';
  }
  
  if (rankedMessage) {
    rankedMessage.style.display = rankedItems.length === 0 ? 'block' : 'none';
  }
}

// Touch support for mobile devices
function enableTouchSupport(sourceList, targetList, inputsContainer, questionId) {
  const items = sourceList.querySelectorAll('.survey-ranking-item');
  
  items.forEach(function(item) {
    setupTouchForItem(item, sourceList, targetList, inputsContainer, questionId);
  });
}

function setupTouchForItem(item, sourceList, targetList, inputsContainer, questionId) {
  let touchItem = null;
  let touchOffset = { x: 0, y: 0 };
  let dragElement = null;
  let placeholder = null;
  
  item.addEventListener('touchstart', function(e) {
    e.preventDefault();
    const touch = e.touches[0];
    touchItem = item;
    
    // Calculate offset
    const rect = item.getBoundingClientRect();
    touchOffset.x = touch.clientX - rect.left;
    touchOffset.y = touch.clientY - rect.top;
    
    // Create a dragging element
    dragElement = item.cloneNode(true);
    dragElement.style.position = 'fixed';
    dragElement.style.zIndex = '10000';
    dragElement.style.opacity = '0.8';
    dragElement.style.pointerEvents = 'none';
    dragElement.style.width = rect.width + 'px';
    dragElement.style.left = (touch.clientX - touchOffset.x) + 'px';
    dragElement.style.top = (touch.clientY - touchOffset.y) + 'px';
    dragElement.classList.add('dragging-touch');
    document.body.appendChild(dragElement);
    
    // Create placeholder
    placeholder = document.createElement('li');
    placeholder.className = 'survey-ranking-placeholder';
    placeholder.style.height = rect.height + 'px';
    placeholder.style.backgroundColor = '#f0f4f8';
    placeholder.style.border = '2px dashed #cbd5e0';
    placeholder.style.borderRadius = '4px';
    placeholder.style.margin = '4px 0';
    
    // Hide original item and insert placeholder
    item.style.opacity = '0.3';
    item.parentNode.insertBefore(placeholder, item);
    
    // Add visual feedback to lists
    sourceList.classList.add('touch-active');
    targetList.classList.add('touch-active');
  }, { passive: false });
  
  item.addEventListener('touchmove', function(e) {
    if (!touchItem || !dragElement) return;
    
    e.preventDefault();
    const touch = e.touches[0];
    
    // Update drag element position
    dragElement.style.left = (touch.clientX - touchOffset.x) + 'px';
    dragElement.style.top = (touch.clientY - touchOffset.y) + 'px';
    
    // Find element under touch point
    dragElement.style.display = 'none';
    const elementBelow = document.elementFromPoint(touch.clientX, touch.clientY);
    dragElement.style.display = '';
    
    if (!elementBelow) return;
    
    // Check if we're over a list
    const listBelow = elementBelow.closest('.survey-ranking-list');
    if (listBelow) {
      // Visual feedback for the list
      document.querySelectorAll('.survey-ranking-list').forEach(function(list) {
        list.classList.remove('drag-over');
      });
      listBelow.classList.add('drag-over');
      
      // Find the closest item to insert before/after
      const afterElement = getTouchDragAfterElement(listBelow, touch.clientY);
      
      if (afterElement == null) {
        listBelow.appendChild(placeholder);
      } else {
        listBelow.insertBefore(placeholder, afterElement);
      }
    }
  }, { passive: false });
  
  item.addEventListener('touchend', function(e) {
    if (!touchItem || !dragElement) return;
    
    e.preventDefault();
    
    // Remove drag element
    if (dragElement) {
      dragElement.remove();
      dragElement = null;
    }
    
    // Get the list where placeholder is
    const newList = placeholder.parentNode;
    
    // Move item to placeholder position
    if (newList) {
      newList.insertBefore(item, placeholder);
      
      // Re-enable touch events for the moved item
      setupTouchForItem(item, newList, 
        newList.id.includes('available') ? targetList : sourceList, 
        inputsContainer, questionId);
      
      // Update inputs and numbering if moved to ranked list
      if (newList.id.includes('ranked')) {
        updateRankingInputs(newList, inputsContainer, questionId);
        updateRankingNumbers(newList);
      } else if (sourceList.id.includes('ranked')) {
        // If moved from ranked list, update that too
        updateRankingInputs(sourceList, inputsContainer, questionId);
        updateRankingNumbers(sourceList);
      }
      
      // Update empty states
      const container = newList.closest('.survey-ranking-container');
      const availableList = container.querySelector('.survey-ranking-available .survey-ranking-list');
      const rankedList = container.querySelector('.survey-ranking-ranked .survey-ranking-list');
      updateEmptyStates(availableList, rankedList);
    }
    
    // Clean up
    if (placeholder) {
      placeholder.remove();
      placeholder = null;
    }
    
    // Reset item opacity
    item.style.opacity = '';
    touchItem = null;
    
    // Remove visual feedback
    document.querySelectorAll('.survey-ranking-list').forEach(function(list) {
      list.classList.remove('drag-over', 'touch-active');
    });
  }, { passive: false });
  
  // Prevent default touch behavior on the item
  item.addEventListener('touchcancel', function(e) {
    // Clean up on cancel
    if (dragElement) {
      dragElement.remove();
      dragElement = null;
    }
    if (placeholder) {
      placeholder.remove();
      placeholder = null;
    }
    if (item) {
      item.style.opacity = '';
    }
    touchItem = null;
    
    document.querySelectorAll('.survey-ranking-list').forEach(function(list) {
      list.classList.remove('drag-over', 'touch-active');
    });
  });
}

function getTouchDragAfterElement(container, y) {
  const draggableElements = [...container.querySelectorAll('.survey-ranking-item:not(.dragging-touch)')];
  
  return draggableElements.reduce((closest, child) => {
    const box = child.getBoundingClientRect();
    const offset = y - box.top - box.height / 2;
    
    if (offset < 0 && offset > closest.offset) {
      return { offset: offset, element: child };
    } else {
      return closest;
    }
  }, { offset: Number.NEGATIVE_INFINITY }).element;
}

// Export functions for potential external use
window.SurveyEngine = window.SurveyEngine || {};
window.SurveyEngine.Matrix = {
  validateAllMatrixRows: validateAllMatrixRows,
  getMatrixCompletionStatus: getMatrixCompletionStatus,
  initializeMatrixQuestions: initializeMatrixQuestions
};

window.SurveyEngine.Ranking = {
  initializeRankingQuestions: initializeRankingQuestions,
  setupRankingQuestion: setupRankingQuestion,
  updateRankingInputs: updateRankingInputs,
  updateRankingNumbers: updateRankingNumbers
};