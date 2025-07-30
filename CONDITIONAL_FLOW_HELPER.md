# SurveyEngine Conditional Flow Helper

A Rails helper for implementing JavaScript-based conditional question flows in surveys.

## Architecture

The helper follows Rails best practices with proper separation of concerns:

- **CSS**: `/app/assets/stylesheets/survey_engine/conditional_flow.css`
- **JavaScript**: `/app/assets/javascripts/survey_engine/conditional_flow.js`
- **Helper Methods**: `/app/helpers/survey_engine/conditional_flow_helper.rb`

## Usage

### Basic Setup

1. **Include CSS** (automatic via asset pipeline):
   ```ruby
   # CSS is automatically included via `*= require_tree .` in application.css
   ```

2. **Include JavaScript** (two options):

   **Option A: Inline (Recommended for development)**
   ```erb
   <%= conditional_flow_javascript_tag %>
   <%= initialize_conditional_flow(@survey) %>
   ```

   **Option B: Asset Pipeline (Recommended for production)**
   ```erb
   <!-- In your layout or view -->
   <%= javascript_include_tag 'survey_engine/conditional_flow' %>
   
   <!-- Then initialize -->
   <%= initialize_conditional_flow(@survey) %>
   ```

### View Implementation

```erb
<%= form_tag submit_answer_survey_path(@survey), class: "se-survey-form" do %>
  <div class="se-questions-container">
    <% @questions.each_with_index do |question, index| %>
      <%= conditional_question_container(question) do %>
        <h3 class="se-question-title">
          <%= index + 1 %>. <%= question.title %>
          <% if question.required? %>
            <span class="se-required">*required</span>
          <% end %>
          <% if question.is_conditional? %>
            <span class="se-conditional-indicator">↳ Conditional</span>
          <% end %>
        </h3>
        
        <div class="se-question-input">
          <% if question.question_type.name == 'scale' %>
            <%= conditional_scale_input(question, @answers[question.id]) %>
          <% else %>
            <!-- Your existing question partials -->
            <%= render partial: "question_#{question.question_type.name}", 
                locals: { question: question, existing_answer: @answers[question.id] } %>
          <% end %>
        </div>
      <% end %>
    <% end %>
  </div>
  
  <%= submit_tag "Complete Survey", class: "se-btn se-btn-success" %>
<% end %>

<!-- Initialize conditional flow -->
<%= conditional_flow_javascript_tag %>
<%= initialize_conditional_flow(@survey) %>
```

## Helper Methods

### `conditional_question_container(question, options = {}, &block)`
Renders a question wrapper with all necessary conditional flow data attributes.

```erb
<%= conditional_question_container(question, class: "custom-class") do %>
  <!-- Question content -->
<% end %>
```

### `conditional_scale_input(question, existing_answer = nil)`
Renders a scale input with conditional flow triggers built-in.

```erb
<%= conditional_scale_input(question, @answers[question.id]) %>
```

### `conditional_flow_attributes(question)`
Returns hash of data attributes for manual use.

```ruby
attrs = conditional_flow_attributes(question)
# => { 'data-question-id' => '123', 'data-is-conditional' => 'true', ... }
```

### `conditional_flow_config(survey)`
Generates JavaScript configuration object.

```erb
<script>
  const config = <%= conditional_flow_config(@survey) %>;
  // Use config...
</script>
```

### `initialize_conditional_flow(survey)`
Generates JavaScript initialization code.

```erb
<%= initialize_conditional_flow(@survey) %>
```

## CSS Classes

### Question States
- `.se-question-card` - Base question styling
- `.se-conditional-question` - Conditional question styling (blue left border)
- `.se-conditional-hidden` - Hidden state (animated)
- `.se-conditional-showing` - Showing animation state

### UI Elements
- `.se-conditional-indicator` - "↳ Conditional" badge
- `.se-progress-conditional` - Progress bar helper text

## Accessibility Features

- **Reduced Motion**: Respects `prefers-reduced-motion: reduce`
- **High Contrast**: Supports `prefers-contrast: high`
- **Keyboard Navigation**: Maintains tab order and focus management
- **Screen Readers**: Proper ARIA attributes and form validation

## JavaScript API

### Global Access
```javascript
// Access the initialized instance
window.surveyConditionalFlow.getDebugInfo()

// Static method for legacy compatibility
SurveyConditionalFlow.handleInputChange(inputElement)
```

### Debug Helpers
```javascript
// Get debug information
const debugInfo = surveyConditionalFlow.getDebugInfo();
console.log(debugInfo);
```

## Performance Features

- **Event Delegation**: Uses single event listener for all inputs
- **Efficient DOM Queries**: Caches elements and uses Map for lookups
- **CSS Transitions**: Hardware-accelerated animations
- **Progressive Enhancement**: Works without JavaScript (shows all questions)

## Browser Support

- Modern browsers (ES6+ features used)
- Graceful degradation for older browsers
- Mobile-responsive design

## Customization

### CSS Customization
Override styles in your application CSS:

```css
.se-conditional-question {
  border-left-color: #your-color;
  background-color: #your-background;
}

.se-conditional-indicator {
  background: #your-color;
  color: #your-text-color;
}
```

### JavaScript Customization
Extend the class for custom behavior:

```javascript
class CustomConditionalFlow extends SurveyConditionalFlow {
  handleQuestionChange(parentQuestionId, selectedValue) {
    // Custom logic here
    super.handleQuestionChange(parentQuestionId, selectedValue);
    
    // Additional custom behavior
    this.trackAnalytics(parentQuestionId, selectedValue);
  }
}
```

## Testing

The helper includes a comprehensive test suite and debug utilities:

```javascript
// Debug the current state
console.log(surveyConditionalFlow.getDebugInfo());

// Test specific conditions
surveyConditionalFlow.handleQuestionChange(questionId, testValue);
```