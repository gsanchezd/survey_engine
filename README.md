# SurveyEngine

A Rails Engine for building comprehensive survey functionality with email-based duplicate prevention and multi-cohort support.

## Overview

SurveyEngine provides a complete survey system designed for scenarios where:
- Each survey is assigned to multiple cohorts (hundreds of cohorts)
- Each person can answer each survey only once per cohort
- Simple email-based access (no complex user management)
- Rich answer types (text, numeric, multiple choice, scales)
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

## Integration in a New Rails Project

### Step 1: Add Routes

Add SurveyEngine routes to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Mount SurveyEngine at the root or a custom path
  mount SurveyEngine::Engine => "/surveys"
  
  # Or mount at root for direct access
  # mount SurveyEngine::Engine => "/"
  
  # Your other routes...
end
```

### Step 2: Generate Views (Optional but Recommended)

Generate customizable view templates:

```bash
$ rails generate survey_engine:views
```

This copies all survey views to `app/views/survey_engine/` in your application, allowing you to customize the appearance. The generator also copies a CSS file with styled components.

Add the stylesheet to your application layout (`app/views/layouts/application.html.erb`):

```erb
<%= stylesheet_link_tag 'survey_engine' %>
```

### Step 3: Seed Question Types

Create the standard question types in your Rails console or seeds file:

```ruby
# db/seeds.rb or rails console

# Create standard question types
question_types = [
  {
    name: "text",
    description: "Free text input",
    allows_options: false,
    allows_multiple_selections: false
  },
  {
    name: "single_choice", 
    description: "Single selection",
    allows_options: true,
    allows_multiple_selections: false
  },
  {
    name: "multiple_choice",
    description: "Multiple selections allowed",
    allows_options: true,
    allows_multiple_selections: true
  },
  {
    name: "scale",
    description: "Numeric scale",
    allows_options: false,
    allows_multiple_selections: false
  },
  {
    name: "boolean",
    description: "Yes/No questions",
    allows_options: false,
    allows_multiple_selections: false
  },
  {
    name: "number",
    description: "Numeric input",
    allows_options: false,
    allows_multiple_selections: false
  }
]

question_types.each do |qt_data|
  SurveyEngine::QuestionType.find_or_create_by(name: qt_data[:name]) do |qt|
    qt.description = qt_data[:description]
    qt.allows_options = qt_data[:allows_options]
    qt.allows_multiple_selections = qt_data[:allows_multiple_selections]
  end
end
```

### Step 4: Create Your First Survey

Use Rails console or create a rake task:

```ruby
# Example: Create a simple feedback survey
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

puts "Survey created! Visit http://localhost:3000/surveys to see it."
```

### Step 5: Customize Appearance (Optional)

The generated views use CSS custom properties for easy theming. Edit `app/assets/stylesheets/survey_engine.css`:

```css
:root {
  --se-primary: #your-brand-color;
  --se-success: #your-success-color;
  /* ... other color variables */
}
```

### Step 6: Add Helper Methods to Your Application (Optional)

Create application helpers for common survey operations:

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def time_duration_in_words(seconds)
    return "0 seconds" if seconds.nil? || seconds.zero?
    
    if seconds < 60
      "#{seconds.round} seconds"
    elsif seconds < 3600
      minutes = (seconds / 60).round
      "#{minutes} minute#{'s' if minutes != 1}"
    else
      hours = (seconds / 3600).round(1)
      "#{hours} hour#{'s' if hours != 1}"
    end
  end
end
```

### Integration Patterns

#### Pattern 1: Standalone Survey Application
Mount the engine at root for a dedicated survey application:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/"
  # All survey routes will be at root level: /surveys, /surveys/:id, etc.
end
```

#### Pattern 2: Survey Module in Existing Application
Mount under a namespace to integrate with existing functionality:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/feedback"
  
  # Your existing routes
  resources :users
  resources :products
  # Survey routes will be at /feedback/surveys, etc.
end
```

#### Pattern 3: Custom Controller Integration
Use the engine models in your own controllers:

```ruby
# app/controllers/admin/surveys_controller.rb
class Admin::SurveysController < ApplicationController
  before_action :authenticate_admin!
  
  def index
    @surveys = SurveyEngine::Survey.includes(:questions, :participants)
  end
  
  def analytics
    @survey = SurveyEngine::Survey.find(params[:id])
    @analytics = calculate_survey_analytics(@survey)
  end
  
  private
  
  def calculate_survey_analytics(survey)
    # Your custom analytics logic using engine models
    {
      total_responses: survey.responses.completed.count,
      completion_rate: survey.participants.completed.count.to_f / survey.participants.count * 100
      # ... more analytics
    }
  end
end
```

### Testing Your Integration

1. **Start your Rails server:**
   ```bash
   rails server
   ```

2. **Visit the surveys index:**
   - If mounted at root: `http://localhost:3000/`
   - If mounted at `/surveys`: `http://localhost:3000/surveys`

3. **Test the survey flow:**
   - View available surveys
   - Start a survey by entering an email
   - Complete the survey
   - View results

### Deployment Considerations

1. **Database Migrations:** Ensure migrations are run in production
2. **Asset Compilation:** The CSS file should be included in asset compilation
3. **UUID Generation:** The engine uses SecureRandom.uuid which works in all environments
4. **Email Validation:** Consider adding email validation in your application layer if needed

### Rails Version Compatibility

This engine is designed for Rails 7.1+ and uses modern Rails features:
- `form_with` for forms
- UUID support for survey routing
- Modern CSS with custom properties
- Zero JavaScript dependencies

## Complete Survey Flow API

### 1. Create Survey Structure

#### Create Survey Template
```ruby
# Create a base survey (template)
survey_template = SurveyEngine::Survey.create!(
  title: "Student Satisfaction Survey Template",
  description: "Evaluate student experience",
  status: "draft"
)
```

#### Add Question Types (one-time setup)
```ruby
# Create standard question types
text_type = SurveyEngine::QuestionType.create!(
  name: "text",
  description: "Free text input",
  allows_options: false,
  allows_multiple_selections: false
)

single_choice_type = SurveyEngine::QuestionType.create!(
  name: "single_choice", 
  description: "Single selection",
  allows_options: true,
  allows_multiple_selections: false
)

multiple_choice_type = SurveyEngine::QuestionType.create!(
  name: "multiple_choice",
  description: "Multiple selections allowed",
  allows_options: true,
  allows_multiple_selections: true
)

scale_type = SurveyEngine::QuestionType.create!(
  name: "scale",
  description: "Numeric scale",
  allows_options: false,
  allows_multiple_selections: false
)

boolean_type = SurveyEngine::QuestionType.create!(
  name: "boolean",
  description: "Yes/No questions",
  allows_options: false,
  allows_multiple_selections: false
)

email_type = SurveyEngine::QuestionType.create!(
  name: "email",
  description: "Email address input",
  allows_options: false,
  allows_multiple_selections: false
)

number_type = SurveyEngine::QuestionType.create!(
  name: "number",
  description: "Numeric input",
  allows_options: false,
  allows_multiple_selections: false
)

date_type = SurveyEngine::QuestionType.create!(
  name: "date",
  description: "Date selection",
  allows_options: false,
  allows_multiple_selections: false
)
```

#### Add Questions to Survey
```ruby
# Text question
text_question = SurveyEngine::Question.create!(
  survey: survey_template,
  question_type: text_type,
  title: "What did you like most about the course?",
  description: "Please be specific",
  is_required: true,
  order_position: 1
)

# Scale question  
scale_question = SurveyEngine::Question.create!(
  survey: survey_template,
  question_type: scale_type,
  title: "How would you rate the overall course?",
  is_required: true,
  order_position: 2,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Poor",
  scale_max_label: "Excellent"
)

# Multiple choice question
choice_question = SurveyEngine::Question.create!(
  survey: survey_template,
  question_type: single_choice_type,
  title: "Which format did you prefer?",
  is_required: true,
  order_position: 3
)

# Add options to choice question
SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "In-person classes",
  option_value: "in_person", 
  order_position: 1
)

SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "Online sessions",
  option_value: "online",
  order_position: 2
)

SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "Hybrid approach",
  option_value: "hybrid",
  order_position: 3
)

# "Other" option with text input
SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "Other",
  option_value: "other",
  order_position: 4,
  is_other: true
)
```

### 2. Deploy Survey to Cohorts

#### Create Survey Per Cohort (Recommended Approach)
```ruby
# Define your cohorts (replace with your actual cohort identifiers)
cohort_ids = [
  "cohort_spring_2024",
  "cohort_summer_2024", 
  "cohort_fall_2024",
  "cohort_enterprise_pilot",
  "cohort_beta_users",
  "cohort_premium_customers"
]

cohort_ids.each do |cohort_id|
  # Create survey for this cohort
  cohort_survey = SurveyEngine::Survey.create!(
    title: "#{survey_template.title} - #{cohort_id}",
    description: survey_template.description,
    status: "draft"
  )
  
  # Copy questions from template
  survey_template.questions.ordered.each do |template_question|
    new_question = SurveyEngine::Question.create!(
      survey: cohort_survey,
      question_type: template_question.question_type,
      title: template_question.title,
      description: template_question.description,
      is_required: template_question.is_required,
      order_position: template_question.order_position,
      scale_min: template_question.scale_min,
      scale_max: template_question.scale_max,
      scale_min_label: template_question.scale_min_label,
      scale_max_label: template_question.scale_max_label
    )
    
    # Copy options if question has them
    template_question.options.ordered.each do |template_option|
      SurveyEngine::Option.create!(
        question: new_question,
        option_text: template_option.option_text,
        option_value: template_option.option_value,
        order_position: template_option.order_position,
        is_other: template_option.is_other,
        is_exclusive: template_option.is_exclusive
      )
    end
  end
  
  # Publish the survey
  cohort_survey.publish!
end
```

### 3. Survey Access & Response Flow

#### Check if User Can Answer Survey
```ruby
def can_user_answer_survey?(survey_id, email)
  survey = SurveyEngine::Survey.find(survey_id)
  
  # Check if survey is available
  return false unless survey.can_receive_responses?
  
  # Check if user already completed it
  participant = SurveyEngine::Participant.find_by(survey: survey, email: email)
  return false if participant&.completed?
  
  true
end
```

#### Start Survey Response
```ruby
def start_survey_response(survey_id, email)
  survey = SurveyEngine::Survey.find(survey_id)
  
  # Find or create participant
  participant = SurveyEngine::Participant.find_or_create_by(
    survey: survey,
    email: email
  ) do |p|
    p.status = 'invited'
  end
  
  # Return if already completed
  return { error: "Survey already completed" } if participant.completed?
  
  # Create response
  response = SurveyEngine::Response.create!(
    survey: survey,
    participant: participant
  )
  
  {
    response_id: response.id,
    questions: survey.questions.ordered.includes(:question_type, :options)
  }
end
```

#### Submit Individual Answer
```ruby
def submit_answer(response_id, question_id, answer_data)
  response = SurveyEngine::Response.find(response_id)
  question = SurveyEngine::Question.find(question_id)
  
  # Validate question belongs to response's survey
  unless question.survey_id == response.survey_id
    return { error: "Question doesn't belong to this survey" }
  end
  
  # Create or update answer
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
    # Clear existing options
    answer.answer_options.destroy_all
    
    # Add selected option
    if answer_data[:option_id]
      option = SurveyEngine::Option.find(answer_data[:option_id])
      answer.answer_options.build(option: option)
      
      # Handle "other" text
      answer.other_text = answer_data[:other_text] if option.is_other?
    end
    
  when 'multiple_choice'
    # Clear existing options
    answer.answer_options.destroy_all
    
    # Add selected options
    if answer_data[:option_ids].present?
      answer_data[:option_ids].each do |option_id|
        option = SurveyEngine::Option.find(option_id)
        answer.answer_options.build(option: option)
      end
      
      # Handle "other" text
      answer.other_text = answer_data[:other_text]
    end
  end
  
  if answer.save
    { success: true, answer: answer }
  else
    { error: answer.errors.full_messages.join(", ") }
  end
end

# Example usage - answering a text question
submit_answer(response_id, text_question.id, { text_answer: "The course was very informative and well-structured" })

# Example usage - answering a scale question  
submit_answer(response_id, scale_question.id, { numeric_answer: 4 })

# Example usage - answering a single choice question
submit_answer(response_id, choice_question.id, { option_id: online_option.id })

# Example usage - answering "other" option with custom text
submit_answer(response_id, choice_question.id, { 
  option_id: other_option.id, 
  other_text: "Combination of recorded videos and live Q&A sessions" 
})
```

#### Complete Survey Response
```ruby
def complete_survey_response(response_id)
  response = SurveyEngine::Response.find(response_id)
  
  # Mark response as completed
  response.complete!
  
  # Mark participant as completed
  response.participant.complete!
  
  {
    success: true,
    completion_percentage: response.completion_percentage,
    completion_time: response.completion_time
  }
end
```

### Complete Survey Response Simulation

Here's a complete example simulating multiple users responding to a survey:

```ruby
# Assume we have a published survey with questions already created
survey = SurveyEngine::Survey.find_by(title: "Student Satisfaction Survey Template - cohort_spring_2024")

# Get the questions for reference
text_question = survey.questions.find_by(order_position: 1)
scale_question = survey.questions.find_by(order_position: 2) 
choice_question = survey.questions.find_by(order_position: 3)

# Get choice options
in_person_option = choice_question.options.find_by(option_value: "in_person")
online_option = choice_question.options.find_by(option_value: "online")
hybrid_option = choice_question.options.find_by(option_value: "hybrid")
other_option = choice_question.options.find_by(option_value: "other")

# Simulate responses from different participants
participants_data = [
  {
    email: "alice.student@university.edu",
    text_answer: "The interactive sessions and practical examples were excellent",
    scale_answer: 5,
    choice_option: in_person_option
  },
  {
    email: "bob.learner@college.edu", 
    text_answer: "Good content but could use more hands-on exercises",
    scale_answer: 4,
    choice_option: hybrid_option
  },
  {
    email: "carol.pupil@school.edu",
    text_answer: "Amazing course! Very well structured and informative",
    scale_answer: 5,
    choice_option: online_option
  },
  {
    email: "david.scholar@academy.edu",
    text_answer: "The course was okay, nothing exceptional",
    scale_answer: 3,
    choice_option: in_person_option
  },
  {
    email: "eve.trainee@institute.edu",
    text_answer: "Loved the flexibility and personalized feedback approach",
    scale_answer: 4,
    choice_option: other_option,
    other_text: "Self-paced online with weekly mentorship calls"
  }
]

# Create responses for each participant
participants_data.each do |participant_data|
  # Create participant
  participant = SurveyEngine::Participant.create!(
    survey: survey,
    email: participant_data[:email],
    status: 'invited'
  )
  
  # Start response
  response = SurveyEngine::Response.create!(
    survey: survey,
    participant: participant
  )
  
  # Answer text question
  text_answer = SurveyEngine::Answer.create!(
    response: response,
    question: text_question,
    text_answer: participant_data[:text_answer]
  )
  
  # Answer scale question
  scale_answer = SurveyEngine::Answer.create!(
    response: response,
    question: scale_question,
    numeric_answer: participant_data[:scale_answer]
  )
  
  # Answer choice question
  choice_answer = SurveyEngine::Answer.create!(
    response: response,
    question: choice_question
  )
  
  # Add the selected option
  SurveyEngine::AnswerOption.create!(
    answer: choice_answer,
    option: participant_data[:choice_option]
  )
  
  # Add other text if it's an "other" option
  if participant_data[:choice_option] == other_option && participant_data[:other_text]
    choice_answer.update!(other_text: participant_data[:other_text])
  end
  
  # Complete the response
  response.complete!
  participant.complete!
  
  puts "✅ #{participant_data[:email]} completed survey"
end

# Display survey results summary
puts "\n📊 SURVEY RESULTS SUMMARY"
puts "=" * 50
puts "Survey: #{survey.title}"
puts "Total Participants: #{survey.participants.count}"
puts "Completed Responses: #{survey.participants.completed.count}"
puts "Completion Rate: #{SurveyEngine::Participant.completion_rate_for_survey(survey)}%"

# Show scale question results
scale_scores = survey.responses.completed
  .joins(:answers)
  .where(survey_engine_answers: { question: scale_question })
  .pluck(:numeric_answer)

puts "\nSatisfaction Ratings (1-5 scale):"
puts "Average: #{(scale_scores.sum.to_f / scale_scores.count).round(2)}"
puts "Distribution: #{scale_scores.group_by(&:itself).transform_values(&:count)}"

# Show choice question results
choice_results = {}
survey.responses.completed.each do |response|
  answer = response.answer_for_question(choice_question)
  if answer&.options&.any?
    option = answer.options.first
    key = option.is_other? ? "Other: #{answer.other_text}" : option.option_text
    choice_results[key] = (choice_results[key] || 0) + 1
  end
end

puts "\nPreferred Format:"
choice_results.each { |format, count| puts "  #{format}: #{count}" }
```

### 4. Analytics & Reporting

#### Survey Analytics
```ruby
def survey_analytics(survey_id)
  survey = SurveyEngine::Survey.find(survey_id)
  
  {
    survey_title: survey.title,
    total_participants: survey.participants_count,
    completed_responses: survey.participants.completed.count,
    completion_rate: SurveyEngine::Participant.completion_rate_for_survey(survey),
    pending_participants: survey.participants.pending.count,
    responses_by_day: survey.responses.completion_rate_by_day
  }
end
```

#### Cross-Cohort Comparison
```ruby
def compare_surveys_by_type(survey_name_pattern)
  surveys = SurveyEngine::Survey.where("title LIKE ?", "%#{survey_name_pattern}%")
  
  surveys.map do |survey|
    {
      survey_title: survey.title,
      cohort: extract_cohort_from_title(survey.title),
      participants_count: survey.participants_count,
      completion_rate: SurveyEngine::Participant.completion_rate_for_survey(survey),
      avg_completion_time: calculate_avg_completion_time(survey)
    }
  end
end

private

def extract_cohort_from_title(title)
  # Extract cohort from title like "Survey - cohort_spring_2024"
  title.split(" - ").last
end

def calculate_avg_completion_time(survey)
  completed_responses = survey.responses.completed
  return 0 if completed_responses.empty?
  
  total_time = completed_responses.sum(&:completion_time)
  (total_time / completed_responses.count).round(2)
end
```

#### Export Survey Data
```ruby
def export_survey_data(survey_id, format: :csv)
  survey = SurveyEngine::Survey.find(survey_id)
  responses = survey.responses.completed.includes(:participant, answers: [:question, :options])
  
  case format
  when :csv
    generate_csv_export(survey, responses)
  when :json
    generate_json_export(survey, responses)
  end
end

private

def generate_csv_export(survey, responses)
  require 'csv'
  
  CSV.generate do |csv|
    # Header row
    headers = ['Participant Email', 'Completed At', 'Completion Time (seconds)']
    survey.questions.ordered.each { |q| headers << q.title }
    csv << headers
    
    # Data rows
    responses.each do |response|
      row = [
        response.participant.email,
        response.completed_at,
        response.completion_time
      ]
      
      survey.questions.ordered.each do |question|
        answer = response.answer_for_question(question)
        row << (answer ? answer.display_value : "")
      end
      
      csv << row
    end
  end
end
```

### 5. Common Query Patterns

#### Find Incomplete Responses
```ruby
# Participants who started but didn't finish
incomplete_participants = SurveyEngine::Participant
  .joins(:response)
  .where(status: 'invited')
  .where(survey: survey)
```

#### Get Question Response Summary
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
    
  when 'scale'
    numeric_answers = answers.pluck(:numeric_answer).compact
    
    {
      question_title: question.title,
      response_count: numeric_answers.count,
      average: numeric_answers.sum.to_f / numeric_answers.count,
      min: numeric_answers.min,
      max: numeric_answers.max,
      distribution: numeric_answers.group_by(&:itself).transform_values(&:count)
    }
  end
end
```

## Model Relationships

```
Survey
├── has_many :questions
├── has_many :participants  
└── has_many :responses

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

## Configuration

The engine uses the `survey_engine_` table prefix for all tables to avoid conflicts with your main application.

## Testing

Run the test suite:
```bash
rails test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`) 
5. Create new Pull Request

## Complete NPS Survey Example

Here's a complete example showing how to build a Net Promoter Score (NPS) survey, answer it, and get results using Rails console commands:

### Step 1: Create the NPS Survey Template

```ruby
# Open Rails console
rails console

# Create question types (if not already created)
## They are created in the migrations, so this is just for reference
# SurveyEngine::QuestionType.create!(
#   name: "scale",
#   description: "Numeric scale questions",
#   allows_options: false,
#   allows_multiple_selections: false
# )

# SurveyEngine::QuestionType.create!(
#   name: "text", 
#   description: "Free text input",
#   allows_options: false,
#   allows_multiple_selections: false
# )

# Create NPS survey template
nps_template = SurveyEngine::Survey.create!(
  title: "Net Promoter Score Survey Template",
  description: "Measure customer satisfaction and loyalty",
  status: "draft"
)

# Get question types
scale_type = SurveyEngine::QuestionType.find_by(name: "scale")
text_type = SurveyEngine::QuestionType.find_by(name: "text")

# Add the main NPS question (0-10 scale)
nps_question = SurveyEngine::Question.create!(
  survey: nps_template,
  question_type: scale_type,
  title: "How likely are you to recommend our service to a friend or colleague?",
  description: "Please rate on a scale from 0 (not at all likely) to 10 (extremely likely)",
  is_required: true,
  order_position: 1,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Not at all likely",
  scale_max_label: "Extremely likely"
)

# Add follow-up question for feedback
feedback_question = SurveyEngine::Question.create!(
  survey: nps_template,
  question_type: text_type,
  title: "What is the primary reason for your score?",
  description: "Please help us understand your rating",
  is_required: false,
  order_position: 2,
  placeholder_text: "Tell us what influenced your rating..."
)

puts "✅ NPS Survey template created with ID: #{nps_template.id}"
```

### Step 2: Deploy to Cohorts

```ruby
# Deploy NPS survey to specific cohorts
cohort_ids = ["cohort_q1_2024", "cohort_q2_2024", "cohort_enterprise_2024"]

nps_surveys = []

cohort_ids.each do |cohort_id|
  # Create cohort-specific survey
  cohort_survey = SurveyEngine::Survey.create!(
    title: "NPS Survey - #{cohort_id}",
    description: nps_template.description,
    status: "draft"
  )
  
  # Copy NPS question
  nps_q = SurveyEngine::Question.create!(
    survey: cohort_survey,
    question_type: scale_type,
    title: nps_question.title,
    description: nps_question.description,
    is_required: nps_question.is_required,
    order_position: nps_question.order_position,
    scale_min: nps_question.scale_min,
    scale_max: nps_question.scale_max,
    scale_min_label: nps_question.scale_min_label,
    scale_max_label: nps_question.scale_max_label
  )
  
  # Copy feedback question
  feedback_q = SurveyEngine::Question.create!(
    survey: cohort_survey,
    question_type: text_type,
    title: feedback_question.title,
    description: feedback_question.description,
    is_required: feedback_question.is_required,
    order_position: feedback_question.order_position,
    placeholder_text: feedback_question.placeholder_text
  )
  
  # Publish the survey
  cohort_survey.publish!
  nps_surveys << cohort_survey
  
  puts "✅ Created and published NPS survey for #{cohort_id} (ID: #{cohort_survey.id})"
end
```

### Step 3: Simulate Survey Responses

```ruby
# Let's work with the first cohort survey
survey = nps_surveys.first
puts "Working with survey: #{survey.title}"

# Get the questions
nps_q = survey.questions.find_by(order_position: 1)
feedback_q = survey.questions.find_by(order_position: 2)

# Simulate various customer responses
customer_responses = [
  { email: "alice@company.com", nps_score: 9, feedback: "Great service, very responsive support team!" },
  { email: "bob@startup.com", nps_score: 7, feedback: "Good overall, but could improve response times" },
  { email: "carol@enterprise.com", nps_score: 10, feedback: "Outstanding! Exceeded all expectations" },
  { email: "david@agency.com", nps_score: 6, feedback: "Average service, nothing special" },
  { email: "eve@tech.com", nps_score: 3, feedback: "Had several issues, support was slow to respond" },
  { email: "frank@consulting.com", nps_score: 8, feedback: "Really solid product, minor UI improvements needed" }
]

# Create responses for each customer
customer_responses.each do |customer|
  # Create participant
  participant = SurveyEngine::Participant.create!(
    survey: survey,
    email: customer[:email],
    status: 'invited'
  )
  
  # Create response
  response = SurveyEngine::Response.create!(
    survey: survey,
    participant: participant
  )
  
  # Answer NPS question
  nps_answer = SurveyEngine::Answer.create!(
    response: response,
    question: nps_q,
    numeric_answer: customer[:nps_score]
  )
  
  # Answer feedback question
  feedback_answer = SurveyEngine::Answer.create!(
    response: response,
    question: feedback_q,
    text_answer: customer[:feedback]
  )
  
  # Complete the response
  response.complete!
  participant.complete!
  
  puts "✅ #{customer[:email]} completed survey (NPS: #{customer[:nps_score]})"
end
```

### Step 4: Calculate NPS Results

```ruby
# Get all completed responses
completed_responses = survey.responses.completed.includes(answers: :question)

# Calculate NPS score
nps_scores = []
feedback_responses = []

completed_responses.each do |response|
  nps_answer = response.answers.joins(:question).find_by(survey_engine_questions: { order_position: 1 })
  feedback_answer = response.answers.joins(:question).find_by(survey_engine_questions: { order_position: 2 })
  
  nps_scores << nps_answer.numeric_answer if nps_answer
  feedback_responses << {
    email: response.participant.email,
    score: nps_answer&.numeric_answer,
    feedback: feedback_answer&.text_answer
  }
end

# Calculate NPS categories
promoters = nps_scores.count { |score| score >= 9 }
passives = nps_scores.count { |score| score >= 7 && score <= 8 }  
detractors = nps_scores.count { |score| score <= 6 }
total_responses = nps_scores.count

# Calculate NPS (Promoters % - Detractors %)
nps_score = ((promoters.to_f / total_responses * 100) - (detractors.to_f / total_responses * 100)).round(1)

puts "\n📊 NPS SURVEY RESULTS"
puts "=" * 50
puts "Survey: #{survey.title}"
puts "Total Responses: #{total_responses}"
puts "Completion Rate: #{SurveyEngine::Participant.completion_rate_for_survey(survey)}%"
puts "\nNPS BREAKDOWN:"
puts "Promoters (9-10): #{promoters} (#{(promoters.to_f/total_responses*100).round(1)}%)"
puts "Passives (7-8):   #{passives} (#{(passives.to_f/total_responses*100).round(1)}%)"
puts "Detractors (0-6): #{detractors} (#{(detractors.to_f/total_responses*100).round(1)}%)"
puts "\n🎯 NET PROMOTER SCORE: #{nps_score}"

# Categorize NPS score
nps_category = case nps_score
               when 70..100 then "Excellent"
               when 50..69 then "Good" 
               when 30..49 then "Needs Improvement"
               when 0..29 then "Poor"
               else "Critical"
               end

puts "📈 NPS Category: #{nps_category}"
```

### Step 5: Analyze Customer Feedback

```ruby
puts "\n💬 CUSTOMER FEEDBACK BY CATEGORY:"
puts "=" * 50

# Group feedback by NPS category
promoter_feedback = feedback_responses.select { |r| r[:score] >= 9 }
passive_feedback = feedback_responses.select { |r| r[:score] >= 7 && r[:score] <= 8 }
detractor_feedback = feedback_responses.select { |r| r[:score] <= 6 }

puts "\n🟢 PROMOTERS (Score 9-10):"
promoter_feedback.each do |response|
  puts "  • #{response[:email]} (#{response[:score]}): \"#{response[:feedback]}\""
end

puts "\n🟡 PASSIVES (Score 7-8):"
passive_feedback.each do |response|
  puts "  • #{response[:email]} (#{response[:score]}): \"#{response[:feedback]}\""
end

puts "\n🔴 DETRACTORS (Score 0-6):"
detractor_feedback.each do |response|
  puts "  • #{response[:email]} (#{response[:score]}): \"#{response[:feedback]}\""
end
```

### Step 6: Export Results to CSV

```ruby
require 'csv'

# Generate CSV export
csv_data = CSV.generate do |csv|
  # Header
  csv << ['Email', 'NPS Score', 'Category', 'Feedback', 'Completed At']
  
  # Data rows
  feedback_responses.each do |response|
    category = case response[:score]
               when 9..10 then 'Promoter'
               when 7..8 then 'Passive'
               when 0..6 then 'Detractor'
               else 'Unknown'
               end
    
    participant = SurveyEngine::Participant.find_by(email: response[:email])
    
    csv << [
      response[:email],
      response[:score],
      category,
      response[:feedback],
      participant.completed_at
    ]
  end
end

# Save to file
File.write("nps_survey_results_#{survey.id}.csv", csv_data)
puts "\n💾 Results exported to: nps_survey_results_#{survey.id}.csv"
```

### Step 7: Compare Across Cohorts

```ruby
puts "\n📈 CROSS-COHORT NPS COMPARISON:"
puts "=" * 50

nps_surveys.each do |cohort_survey|
  responses = cohort_survey.responses.completed.includes(answers: :question)
  
  if responses.any?
    scores = responses.map do |response|
      nps_answer = response.answers.joins(:question).find_by(survey_engine_questions: { order_position: 1 })
      nps_answer&.numeric_answer
    end.compact
    
    if scores.any?
      promoters = scores.count { |score| score >= 9 }
      detractors = scores.count { |score| score <= 6 }
      total = scores.count
      cohort_nps = ((promoters.to_f / total * 100) - (detractors.to_f / total * 100)).round(1)
      
      cohort_name = cohort_survey.title.split(" - ").last
      puts "#{cohort_name.ljust(25)} | NPS: #{cohort_nps.to_s.rjust(6)} | Responses: #{total}"
    end
  else
    puts "#{cohort_survey.title} - No responses yet"
  end
end
```

### Expected Output:

```
✅ NPS Survey template created with ID: 1
✅ Created and published NPS survey for cohort_q1_2024 (ID: 2)
✅ Created and published NPS survey for cohort_q2_2024 (ID: 3)
✅ Created and published NPS survey for cohort_enterprise_2024 (ID: 4)

✅ alice@company.com completed survey (NPS: 9)
✅ bob@startup.com completed survey (NPS: 7)
✅ carol@enterprise.com completed survey (NPS: 10)
✅ david@agency.com completed survey (NPS: 6)
✅ eve@tech.com completed survey (NPS: 3)
✅ frank@consulting.com completed survey (NPS: 8)

📊 NPS SURVEY RESULTS
==================================================
Survey: NPS Survey - cohort_q1_2024
Total Responses: 6
Completion Rate: 100.0%

NPS BREAKDOWN:
Promoters (9-10): 2 (33.3%)
Passives (7-8):   2 (33.3%)
Detractors (0-6): 2 (33.3%)

🎯 NET PROMOTER SCORE: 0.0
📈 NPS Category: Critical

💬 CUSTOMER FEEDBACK BY CATEGORY:
==================================================

🟢 PROMOTERS (Score 9-10):
  • alice@company.com (9): "Great service, very responsive support team!"
  • carol@enterprise.com (10): "Outstanding! Exceeded all expectations"

🟡 PASSIVES (Score 7-8):
  • bob@startup.com (7): "Good overall, but could improve response times"  
  • frank@consulting.com (8): "Really solid product, minor UI improvements needed"

🔴 DETRACTORS (Score 0-6):
  • david@agency.com (6): "Average service, nothing special"
  • eve@tech.com (3): "Had several issues, support was slow to respond"

💾 Results exported to: nps_survey_results_2.csv

📈 CROSS-COHORT NPS COMPARISON:
==================================================
cohort_q1_2024            | NPS:    0.0 | Responses: 6
cohort_q2_2024            | NPS:      - | Responses: 0
cohort_enterprise_2024    | NPS:      - | Responses: 0
```

This complete example shows the full lifecycle from survey creation to detailed NPS analysis and reporting!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
