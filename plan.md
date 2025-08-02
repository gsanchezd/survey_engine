# Survey Engine Development Plan

## Current Priority: Range Conditional Logic

### Feature: Add Range Conditional Logic for NPS Passives (7-8)

**Problem:** Cannot handle NPS Passives (score 7-8) - need range conditions  
**Current limitation:** Only single condition operators (`>=`, `<=`, `==`, etc.)  
**Needed:** Multiple conditions with AND/OR logic

**Use Case:**
```ruby
# Currently missing: Show question if NPS >= 7 AND NPS <= 8
# For question: "¿Qué podríamos mejorar para aumentar la nota?"
```

**Implementation Plan:**

#### 1. Database Migration
```ruby
# Add to questions table:
add_column :survey_engine_questions, :conditional_operator_2, :string
add_column :survey_engine_questions, :conditional_value_2, :decimal
add_column :survey_engine_questions, :conditional_logic_type, :string # 'AND', 'OR'
```

#### 2. Model Updates
```ruby
# Add to Question model:
validates :conditional_logic_type, inclusion: { in: %w[AND OR], allow_nil: true }
validates :conditional_operator_2, inclusion: { in: %w[less_than greater_than equal_to greater_than_or_equal less_than_or_equal], allow_nil: true }

# New evaluation methods:
def has_complex_condition?
  conditional_operator_2.present? && conditional_value_2.present?
end

def evaluate_complex_condition(answer_value)
  condition1 = evaluate_condition(answer_value)
  return condition1 unless has_complex_condition?
  
  condition2 = evaluate_second_condition(answer_value)
  conditional_logic_type == 'AND' ? (condition1 && condition2) : (condition1 || condition2)
end

def evaluate_second_condition(answer_value)
  return false if conditional_operator_2.blank? || conditional_value_2.blank?
  
  case conditional_operator_2
  when 'less_than' then answer_value < conditional_value_2
  when 'greater_than' then answer_value > conditional_value_2
  when 'equal_to' then answer_value == conditional_value_2
  when 'greater_than_or_equal' then answer_value >= conditional_value_2
  when 'less_than_or_equal' then answer_value <= conditional_value_2
  else false
  end
end
```

#### 3. Validation Updates
```ruby
# Add to existing conditional_logic_is_valid method:
def conditional_logic_is_valid
  # ... existing validations ...
  
  # Complex condition validations
  if conditional_operator_2.present? || conditional_value_2.present? || conditional_logic_type.present?
    errors.add(:conditional_operator_2, 'is required for complex conditions') if conditional_operator_2.blank?
    errors.add(:conditional_value_2, 'is required for complex conditions') if conditional_value_2.blank?
    errors.add(:conditional_logic_type, 'is required for complex conditions') if conditional_logic_type.blank?
  end
  
  # Ensure first condition exists if second condition is provided
  if has_complex_condition? && !is_conditional?
    errors.add(:base, 'First condition is required for complex conditional logic')
  end
end
```

#### 4. Test Coverage
```ruby
# Add tests for range conditions:
test "should evaluate complex AND condition correctly" do
  # NPS >= 7 AND NPS <= 8 (Passives)
  question = create_complex_conditional_question(
    operator1: 'greater_than_or_equal', value1: 7,
    operator2: 'less_than_or_equal', value2: 8,
    logic_type: 'AND'
  )
  
  assert_not question.should_show?(6)  # Below range
  assert question.should_show?(7)      # In range
  assert question.should_show?(8)      # In range  
  assert_not question.should_show?(9)  # Above range
end

test "should evaluate complex OR condition correctly" do
  # NPS <= 3 OR NPS >= 9 (Very negative or very positive)
  question = create_complex_conditional_question(
    operator1: 'less_than_or_equal', value1: 3,
    operator2: 'greater_than_or_equal', value2: 9,
    logic_type: 'OR'
  )
  
  assert question.should_show?(2)      # Matches first condition
  assert_not question.should_show?(5)  # Matches neither
  assert question.should_show?(10)     # Matches second condition
end
```

#### 5. Survey Update
```ruby
# Enable Passives question in student satisfaction survey:
passives_question = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué podríamos mejorar para aumentar la nota?",
  question_type: multiple_choice_type,
  is_required: true,
  conditional_parent: nps_question,
  conditional_operator: 'greater_than_or_equal',
  conditional_value: 7,
  conditional_operator_2: 'less_than_or_equal', 
  conditional_value_2: 8,
  conditional_logic_type: 'AND',
  show_if_condition_met: true
)
```

**Files to Modify:**
- `db/migrate/add_range_conditional_logic_to_questions.rb`
- `app/models/survey_engine/question.rb`
- `test/models/survey_engine/question_test.rb`
- `create_student_satisfaction_survey.rb`

**Expected Impact:**
- ✅ Complete NPS survey support (Detractors, Passives, Promoters)
- ✅ 100% of Student Satisfaction Survey questions functional
- ✅ Advanced conditional logic for future surveys

**Estimated Effort:** 4-6 hours

**Priority:** High (blocks complete Student Satisfaction Survey)

---

## Secondary Priority: Matrix Question Views

### Feature: Create Views for Matrix Questions

**Problem:** Matrix questions have complete backend support but no frontend rendering  
**Current state:** Models, validations, and logic complete - views missing  
**Needed:** HTML views, CSS styling, and JavaScript interaction for matrix questions

**Use Case:**
```erb
<!-- Render matrix question like the image example -->
<div class="matrix-question">
  <h3><%= matrix_question.title %></h3>
  <p><%= matrix_question.description %></p>
  
  <table class="matrix-table">
    <thead>
      <tr>
        <th></th>
        <% matrix_question.options.each do |option| %>
          <th><%= option.option_text %></th>
        <% end %>
      </tr>
    </thead>
    <tbody>
      <% matrix_question.matrix_sub_questions.each do |row| %>
        <tr>
          <td class="matrix-row-label"><%= row.matrix_row_text %></td>
          <% matrix_question.options.each do |option| %>
            <td class="matrix-cell">
              <input type="radio" name="answer[<%= row.id %>]" value="<%= option.id %>" />
            </td>
          <% end %>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

**Implementation Plan:**

#### 1. Matrix Question Partial
```erb
<!-- app/views/survey_engine/questions/_matrix_question.html.erb -->
<div class="survey-question matrix-question" data-question-id="<%= question.id %>">
  <div class="question-header">
    <h3 class="question-title">
      <%= question.title %>
      <% if question.required? %>
        <span class="required-indicator">*</span>
      <% end %>
    </h3>
    
    <% if question.description.present? %>
      <p class="question-description"><%= question.description %></p>
    <% end %>
  </div>

  <div class="matrix-container">
    <table class="matrix-table">
      <thead>
        <tr>
          <th class="matrix-row-header"></th>
          <% question.options.ordered.each do |option| %>
            <th class="matrix-column-header">
              <span class="column-label"><%= option.option_text %></span>
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <% question.matrix_sub_questions.ordered.each do |sub_question| %>
          <tr class="matrix-row" data-row-id="<%= sub_question.id %>">
            <td class="matrix-row-label">
              <%= sub_question.matrix_row_text %>
              <% if sub_question.required? %>
                <span class="required-indicator">*</span>
              <% end %>
            </td>
            <% question.options.ordered.each do |option| %>
              <td class="matrix-cell">
                <%= radio_button_tag "answer[#{sub_question.id}]", 
                                   option.id, 
                                   false,
                                   class: "matrix-radio",
                                   data: { 
                                     question_id: sub_question.id,
                                     option_id: option.id 
                                   } %>
                <%= label_tag "answer_#{sub_question.id}_#{option.id}", 
                            option.option_text, 
                            class: "sr-only" %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>

  <% if question.help_text.present? %>
    <p class="question-help-text"><%= question.help_text %></p>
  <% end %>
</div>
```

#### 2. CSS Styling
```scss
// app/assets/stylesheets/survey_engine/matrix_questions.scss
.matrix-question {
  margin-bottom: 2rem;

  .question-header {
    margin-bottom: 1rem;
    
    .question-title {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: #1f2937;
    }
    
    .question-description {
      color: #6b7280;
      font-size: 0.875rem;
      line-height: 1.5;
    }
  }

  .matrix-container {
    overflow-x: auto;
    border: 1px solid #e5e7eb;
    border-radius: 0.5rem;
  }

  .matrix-table {
    width: 100%;
    border-collapse: collapse;
    background: white;

    th, td {
      padding: 0.75rem;
      text-align: center;
      border-bottom: 1px solid #e5e7eb;
    }

    th {
      background-color: #f9fafb;
      font-weight: 600;
      color: #374151;
      border-right: 1px solid #e5e7eb;
    }

    .matrix-row-header,
    .matrix-row-label {
      text-align: left;
      background-color: #f9fafb;
      font-weight: 500;
      width: 40%;
    }

    .matrix-cell {
      width: 60px;
      border-right: 1px solid #e5e7eb;
      position: relative;

      .matrix-radio {
        margin: 0;
        transform: scale(1.2);
      }

      &:hover {
        background-color: #f3f4f6;
      }
    }

    tbody tr:hover {
      background-color: #f9fafb;
    }
  }

  .required-indicator {
    color: #ef4444;
  }

  .question-help-text {
    margin-top: 0.5rem;
    font-size: 0.875rem;
    color: #6b7280;
    font-style: italic;
  }
}

// Responsive design
@media (max-width: 768px) {
  .matrix-question {
    .matrix-container {
      font-size: 0.875rem;
    }
    
    .matrix-table {
      th, td {
        padding: 0.5rem 0.25rem;
      }
      
      .matrix-row-label {
        font-size: 0.8rem;
      }
    }
  }
}
```

#### 3. JavaScript Interaction
```javascript
// app/assets/javascripts/survey_engine/matrix_questions.js
document.addEventListener('DOMContentLoaded', function() {
  // Matrix question interaction
  const matrixQuestions = document.querySelectorAll('.matrix-question');
  
  matrixQuestions.forEach(function(matrixQuestion) {
    const radioButtons = matrixQuestion.querySelectorAll('.matrix-radio');
    
    // Add change event listeners
    radioButtons.forEach(function(radio) {
      radio.addEventListener('change', function() {
        handleMatrixChange(this);
      });
    });
    
    // Add keyboard navigation
    matrixQuestion.addEventListener('keydown', function(e) {
      handleMatrixKeyboard(e);
    });
  });
});

function handleMatrixChange(radio) {
  const row = radio.closest('.matrix-row');
  const questionId = radio.dataset.questionId;
  const optionId = radio.dataset.optionId;
  
  // Clear previous selection styling in row
  row.querySelectorAll('.matrix-cell').forEach(function(cell) {
    cell.classList.remove('selected');
  });
  
  // Add selection styling
  radio.closest('.matrix-cell').classList.add('selected');
  
  // Trigger validation check
  validateMatrixRow(row);
  
  // Optional: Auto-save functionality
  if (typeof autoSaveAnswer === 'function') {
    autoSaveAnswer(questionId, optionId);
  }
}

function validateMatrixRow(row) {
  const radios = row.querySelectorAll('.matrix-radio');
  const isAnswered = Array.from(radios).some(radio => radio.checked);
  
  row.classList.toggle('answered', isAnswered);
  row.classList.toggle('unanswered', !isAnswered);
  
  return isAnswered;
}

function handleMatrixKeyboard(e) {
  // Arrow key navigation within matrix
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
    e.preventDefault();
    navigateMatrix(e.target, e.key);
  }
}

function navigateMatrix(currentElement, direction) {
  // Implementation for keyboard navigation between matrix cells
  // Enhance accessibility
}
```

#### 4. Question Type Detection
```erb
<!-- Update main question partial to detect matrix questions -->
<!-- app/views/survey_engine/questions/_question.html.erb -->
<% if question.is_matrix? %>
  <%= render 'survey_engine/questions/matrix_question', question: question %>
<% elsif question.is_matrix_row? %>
  <!-- Matrix rows are rendered by their parent matrix question -->
<% else %>
  <!-- Render regular question types -->
  <%= render "survey_engine/questions/#{question.question_type.name}_question", question: question %>
<% end %>
```

#### 5. Form Integration
```ruby
# Update surveys controller to handle matrix answers
def process_matrix_answers(matrix_question, params)
  matrix_question.matrix_sub_questions.each do |sub_question|
    if params[:answer] && params[:answer][sub_question.id.to_s]
      option_id = params[:answer][sub_question.id.to_s]
      
      # Create or update answer for this matrix row
      answer = Answer.find_or_initialize_by(
        response: @response,
        question: sub_question
      )
      
      # Clear existing selections
      answer.answer_options.destroy_all
      
      # Add new selection
      option = Option.find(option_id)
      answer.answer_options.build(option: option)
      answer.save!
    end
  end
end
```

**Files to Create/Modify:**
- `app/views/survey_engine/questions/_matrix_question.html.erb`
- `app/assets/stylesheets/survey_engine/matrix_questions.scss`
- `app/assets/javascripts/survey_engine/matrix_questions.js`
- `app/views/survey_engine/questions/_question.html.erb`
- `app/controllers/survey_engine/surveys_controller.rb`

**Expected Impact:**
- ✅ Matrix questions fully functional in UI
- ✅ Professional table-based layout matching design requirements
- ✅ Responsive design for mobile devices
- ✅ Accessibility compliance with keyboard navigation
- ✅ Form integration for answer submission

**Estimated Effort:** 6-8 hours

**Priority:** High (required to test and use matrix questions)