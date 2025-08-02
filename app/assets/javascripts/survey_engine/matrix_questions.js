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