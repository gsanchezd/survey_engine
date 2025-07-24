# SurveyEngine

A Rails Engine for building comprehensive survey functionality with email-based duplicate prevention.

## Overview

SurveyEngine provides a complete survey system designed for scenarios where:
- Each person can answer each survey only once (email-based tracking)
- Rich answer types (text, numeric, multiple choice, scales)
- UUID-based survey routing
- Polymorphic associations - surveys can belong to any resource (cohorts, courses, etc.)
- Comprehensive analytics and reporting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'survey_engine'
```

And then execute:
```bash
$ bundle install
$ rails survey_engine:install:migrations
$ rails db:migrate
```

## Quick Start

### 1. Mount the Engine

Add SurveyEngine routes to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/surveys"
  # Your other routes...
end
```

### 2. Generate Components (Optional)

Generate customizable templates:

```bash
# Copy views for customization
$ rails generate survey_engine:views

# Copy controllers for customization  
$ rails generate survey_engine:controllers
```

The views generator will automatically copy:
- All survey view templates to `app/views/survey_engine/`
- CSS file to `app/assets/stylesheets/survey_engine.css`

Add the stylesheet to your application layout:

```erb
<%= stylesheet_link_tag 'survey_engine/application' %>
```

#### Styling System

The engine includes a comprehensive CSS system with:

- **CSS Custom Properties**: Easy theme customization via CSS variables
- **Responsive Design**: Mobile-first approach with breakpoints
- **Component-Based Classes**: Modular styling system

**CSS Variable Customization:**
```css
/* Override in your application.css */
:root {
  --survey-primary-color: #your-brand-color;
  --survey-success-color: #your-success-color;
  --survey-spacing: 16px; /* Adjust spacing */
  --survey-font-family: 'Your Font', sans-serif;
}
```

**Key CSS Classes:**
- `.survey-container` - Main wrapper with responsive padding
- `.survey-alert-*` - Alert panels (info, success, warning, danger)
- `.survey-btn-*` - Button variants (primary, success, secondary)
- `.survey-question` - Individual question containers
- `.survey-form-*` - Form elements and layout

### 3. Create Your First Survey

Question types are automatically seeded via migration. Create a survey:

```ruby
# Create survey
survey = SurveyEngine::Survey.create!(
  title: "Customer Feedback Survey",
  description: "Help us improve our service",
  status: "published",
  is_active: true
)

# Add a text question
text_type = SurveyEngine::QuestionType.find_by(name: "text")
SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "What did you like most about our service?",
  is_required: true,
  order_position: 1
)

# Add a scale question
scale_type = SurveyEngine::QuestionType.find_by(name: "scale")
SurveyEngine::Question.create!(
  survey: survey,
  question_type: scale_type,
  title: "How would you rate our service overall?",
  is_required: true,
  order_position: 2,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Poor",
  scale_max_label: "Excellent"
)

puts "Survey created! Visit /surveys/#{survey.uuid}"
```

## Making Resources Surveyable

SurveyEngine supports polymorphic associations, allowing surveys to be attached to any resource in your application.

### 1. Include the Surveyable Concern

Add the `SurveyEngine::Surveyable` concern to any model that should have surveys:

```ruby
class Cohort < ApplicationRecord
  include SurveyEngine::Surveyable
end

class Course < ApplicationRecord
  include SurveyEngine::Surveyable
end

class Organization < ApplicationRecord
  include SurveyEngine::Surveyable
end
```

### 2. Create Resource-Specific Surveys

```ruby
# Create survey for a specific cohort
cohort = Cohort.find(1)
survey = cohort.create_survey(
  title: "Cohort Satisfaction Survey",
  description: "Please rate your experience with this cohort",
  status: "draft"
)

# Or create manually with explicit association
course = Course.find(1)
survey = SurveyEngine::Survey.create(
  title: "Course Evaluation",
  description: "Help us improve this course",
  surveyable: course,
  status: "published",
  is_active: true
)
```

### 3. Query Surveys by Resource

```ruby
# Get all surveys for a specific resource
cohort.surveys                    # All surveys
cohort.active_surveys            # Only active surveys
cohort.published_surveys         # Only published surveys
cohort.current_surveys           # Non-expired surveys

# Query across all surveys
SurveyEngine::Survey.for_surveyable(cohort)           # Surveys for specific cohort
SurveyEngine::Survey.for_surveyable_type("Cohort")    # All cohort surveys

# Global surveys (not tied to any resource)
SurveyEngine::Survey.global_surveys                   # Global surveys only
SurveyEngine::Survey.where(surveyable: nil)          # Same as above
```

### 4. Available Methods on Surveyable Resources

When you include `SurveyEngine::Surveyable`, your models gain these methods:

```ruby
# Survey management
cohort.surveys                           # All surveys for this resource
cohort.create_survey(attributes)         # Create new survey
cohort.find_survey_by_uuid(uuid)        # Find survey by UUID

# Survey filtering
cohort.active_surveys                    # Only active surveys
cohort.published_surveys                 # Only published surveys  
cohort.current_surveys                   # Non-expired surveys

# Analytics
cohort.survey_responses_count            # Total responses across all surveys
cohort.survey_participants_count         # Total participants across all surveys

# Permission control
cohort.can_have_surveys?                 # Override to control survey access
```

### 5. Global vs Resource-Specific Surveys

```ruby
# Global survey (available to all users)
global_survey = SurveyEngine::Survey.create(
  title: "Company-wide Satisfaction Survey",
  global: true,
  surveyable: nil,  # No specific resource
  status: "published"
)

# Resource-specific survey
cohort_survey = cohort.create_survey(
  title: "Cohort-specific Feedback",
  global: false,    # Default
  status: "published"
)

# Query patterns
SurveyEngine::Survey.global_surveys      # Only global surveys
SurveyEngine::Survey.local_surveys       # Only resource-specific surveys
```

## Question Types

The engine includes these built-in question types:

- **text** - Free text input
- **single_choice** - Radio buttons (one selection)
- **multiple_choice** - Checkboxes (multiple selections)
- **scale** - Numeric scale/rating
- **boolean** - Yes/No questions
- **number** - Numeric input

## Integration Patterns

### Pattern 1: Standalone Survey Application
```ruby
# Mount at root for dedicated survey app
Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/"
end
```

### Pattern 2: Survey Module in Existing App
```ruby
# Mount under namespace
Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/feedback"
  # Your existing routes...
end
```

### Pattern 3: Custom Controller Integration
```ruby
# Use engine models in your controllers
class Admin::SurveysController < ApplicationController
  def index
    @surveys = SurveyEngine::Survey.includes(:questions, :participants)
  end
  
  def analytics
    @survey = SurveyEngine::Survey.find(params[:id])
    # Your custom analytics using engine models
  end
end
```

## Survey Response Flow

### 1. Check if User Can Answer
```ruby
def can_user_answer_survey?(survey_id, email)
  survey = SurveyEngine::Survey.find(survey_id)
  return false unless survey.can_receive_responses?
  
  participant = SurveyEngine::Participant.find_by(survey: survey, email: email)
  return false if participant&.completed?
  
  true
end
```

### 2. Start Survey Response
```ruby
def start_survey_response(survey_id, email)
  survey = SurveyEngine::Survey.find(survey_id)
  
  participant = SurveyEngine::Participant.find_or_create_by(
    survey: survey,
    email: email
  ) do |p|
    p.status = 'invited'
  end
  
  return { error: "Already completed" } if participant.completed?
  
  response = SurveyEngine::Response.create!(
    survey: survey,
    participant: participant
  )
  
  { response_id: response.id, questions: survey.questions.ordered }
end
```

### 3. Submit Answer
```ruby
def submit_answer(response_id, question_id, answer_data)
  response = SurveyEngine::Response.find(response_id)
  question = SurveyEngine::Question.find(question_id)
  
  answer = SurveyEngine::Answer.find_or_initialize_by(
    response: response,
    question: question
  )
  
  case question.question_type.name
  when 'text'
    answer.text_answer = answer_data[:text_answer]
  when 'scale'
    answer.numeric_answer = answer_data[:numeric_answer]
  when 'single_choice'
    answer.answer_options.destroy_all
    if answer_data[:option_id]
      option = SurveyEngine::Option.find(answer_data[:option_id])
      answer.answer_options.build(option: option)
    end
  end
  
  answer.save
end
```

### 4. Complete Survey
```ruby
def complete_survey_response(response_id)
  response = SurveyEngine::Response.find(response_id)
  response.complete!
  response.participant.complete!
end
```

## Model Relationships

```
Survey
├── belongs_to :surveyable (polymorphic, optional)
├── has_many :questions
├── has_many :participants  
└── has_many :responses

Surveyable Resource (Cohort, Course, etc.)
└── has_many :surveys (as :surveyable)

Question
├── belongs_to :survey
├── belongs_to :question_type
├── has_many :options
└── has_many :answers

Participant  
├── belongs_to :survey
└── has_one :response

Response
├── belongs_to :survey
├── belongs_to :participant
└── has_many :answers

Answer
├── belongs_to :response
├── belongs_to :question
├── has_many :answer_options
└── has_many :options (through answer_options)
```

## Analytics Examples

### Basic Survey Analytics
```ruby
def survey_analytics(survey_id)
  survey = SurveyEngine::Survey.find(survey_id)
  
  {
    survey_title: survey.title,
    surveyable_type: survey.surveyable_type,
    surveyable_id: survey.surveyable_id,
    total_participants: survey.participants_count,
    completed_responses: survey.participants.completed.count,
    completion_rate: (survey.participants.completed.count.to_f / survey.participants.count * 100).round(2),
    pending_participants: survey.participants.pending.count
  }
end
```

### Resource-Specific Analytics
```ruby
# Analytics for all surveys belonging to a resource
def cohort_survey_analytics(cohort)
  surveys = cohort.surveys.published
  
  {
    cohort_name: cohort.name,
    total_surveys: surveys.count,
    active_surveys: cohort.active_surveys.count,
    total_participants: cohort.survey_participants_count,
    total_responses: cohort.survey_responses_count,
    average_completion_rate: calculate_average_completion_rate(surveys)
  }
end

def calculate_average_completion_rate(surveys)
  return 0 if surveys.empty?
  
  rates = surveys.map do |survey|
    total = survey.participants.count
    completed = survey.participants.completed.count
    total > 0 ? (completed.to_f / total * 100) : 0
  end
  
  (rates.sum / rates.size).round(2)
end
```

### Question Response Summary
```ruby
def question_response_summary(question_id)
  question = SurveyEngine::Question.find(question_id)
  answers = question.answers.includes(:options)
  
  case question.question_type.name
  when 'text'
    {
      question_title: question.title,
      response_count: answers.count,
      responses: answers.pluck(:text_answer)
    }
  when 'scale'
    numeric_answers = answers.pluck(:numeric_answer).compact
    {
      question_title: question.title,
      response_count: numeric_answers.count,
      average: numeric_answers.sum.to_f / numeric_answers.count,
      distribution: numeric_answers.group_by(&:itself).transform_values(&:count)
    }
  when 'single_choice', 'multiple_choice'
    option_counts = {}
    answers.each do |answer|
      answer.options.each do |option|
        option_counts[option.option_text] ||= 0
        option_counts[option.option_text] += 1
      end
    end
    {
      question_title: question.title,
      response_count: answers.count,
      option_breakdown: option_counts
    }
  end
end
```

## NPS Survey Example

Complete example creating an NPS survey:

```ruby
# Create NPS survey
nps_survey = SurveyEngine::Survey.create!(
  title: "Net Promoter Score Survey",
  description: "Rate your likelihood to recommend us",
  status: "published",
  is_active: true
)

# Add NPS question (0-10 scale)
scale_type = SurveyEngine::QuestionType.find_by(name: "scale")
nps_question = SurveyEngine::Question.create!(
  survey: nps_survey,
  question_type: scale_type,
  title: "How likely are you to recommend our service?",
  is_required: true,
  order_position: 1,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Not at all likely",
  scale_max_label: "Extremely likely"
)

# Add feedback question
text_type = SurveyEngine::QuestionType.find_by(name: "text")
SurveyEngine::Question.create!(
  survey: nps_survey,
  question_type: text_type,
  title: "What is the primary reason for your score?",
  is_required: false,
  order_position: 2
)

# Calculate NPS from responses
def calculate_nps(survey)
  scores = survey.responses.completed
    .joins(:answers)
    .where(survey_engine_answers: { question: nps_question })
    .pluck(:numeric_answer)
  
  promoters = scores.count { |score| score >= 9 }
  detractors = scores.count { |score| score <= 6 }
  total = scores.count
  
  return 0 if total.zero?
  
  ((promoters.to_f / total * 100) - (detractors.to_f / total * 100)).round(1)
end
```

## Configuration

The engine uses the `survey_engine_` table prefix for all tables to avoid conflicts.

## Testing

```bash
rails test
```

## Rails Version Compatibility

Rails 7.1+ required. Uses modern Rails features:
- UUID support for routing
- Modern CSS with custom properties
- Zero JavaScript dependencies

## License

MIT License