# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SurveyEngine is a Rails Engine gem for building survey functionality. It follows the standard Rails Engine architecture with isolated namespace and modular design.

## Development Commands

### Testing
- Run all tests: `bin/rails test`
- Run specific test: `bin/rails test test/path/to/test_file.rb`
- Prepare test database: `bin/rails db:test:prepare`

### Linting and Code Style
- Run RuboCop linter: `bin/rubocop`
- Auto-fix style issues: `bin/rubocop -a`
- Uses rubocop-rails-omakase for Rails styling conventions

### Gem Development
- Build gem: `gem build survey_engine.gemspec`
- Install locally: `gem install survey_engine-0.1.0.gem`
- Release gem: `rake release` (when ready for production)

### Rails Engine Development
- Start dummy app server: `cd test/dummy && bin/rails server`
- Generate migrations: `bin/rails generate migration MigrationName`
- Run migrations: `bin/rails db:migrate`

## Architecture

### Rails Engine Structure
- **Isolated Namespace**: Uses `SurveyEngine` module with isolated namespace
- **Engine Class**: `SurveyEngine::Engine < ::Rails::Engine` in `lib/survey_engine/engine.rb`
- **Main Module**: Entry point in `lib/survey_engine.rb`

### Directory Structure
- `app/`: Standard Rails MVC structure with SurveyEngine namespace
- `lib/survey_engine/`: Core engine files and modules
- `test/dummy/`: Complete Rails application for testing the engine
- `test/`: Engine-specific tests and test helpers

### Key Files
- `lib/survey_engine/engine.rb`: Main engine configuration
- `lib/survey_engine/version.rb`: Gem version management
- `survey_engine.gemspec`: Gem specification and dependencies
- `test/test_helper.rb`: Test configuration with dummy app integration

### Dependencies
- Rails 8.0.2+ (main dependency)
- SQLite3 (development database)
- Puma (web server)
- Propshaft (asset pipeline)

### Testing Setup
- Uses Rails' built-in testing framework
- Dummy application in `test/dummy/` for integration testing
- Test helper loads dummy environment and configures fixtures
- CI pipeline runs both linting and test suites

## Database Schema

### Core Tables

#### surveys
Main survey/questionnaire entity with linear structure.
- `id` (PK): Unique identifier
- `title`: Survey title
- `description`: Survey description
- `is_active`: Boolean, whether survey is active
- `published_at`: When survey went live
- `expires_at`: Survey expiration date
- `status`: Enum (draft, published, paused, archived)
- `created_at`, `updated_at`: Timestamps

#### question_types
Defines possible question types with specific multiple choice support.
- `id` (PK): Unique identifier
- `name`: Type name (e.g., "single_choice", "multiple_choice", "text", "scale")
- `allows_options`: Boolean, if this type supports options
- `allows_multiple_selections`: Boolean, if multiple selections allowed
- `created_at`: Timestamp

**Standard Question Types:**
- `text`: Open-ended text input
- `textarea`: Long text input
- `number`: Numeric input
- `scale`: Likert scale or rating
- `single_choice`: Radio buttons (one selection)
- `multiple_choice`: Checkboxes (multiple selections)
- `dropdown_single`: Dropdown with single selection
- `dropdown_multiple`: Multi-select dropdown
- `boolean`: Yes/No or True/False
- `date`: Date picker
- `email`: Email input with validation

#### questions
Questions within surveys with enhanced multiple choice support.
- `id` (PK): Unique identifier
- `survey_id` (FK): Reference to surveys
- `question_type_id` (FK): Reference to question_types
- `title`: Main question text
- `description`: Help text for question
- `is_required`: Boolean, if question must be answered
- `order_position`: Position/order in survey
- `scale_min`, `scale_max`: Min/max values for scale questions
- `scale_min_label`, `scale_max_label`: Labels for scale endpoints
- `max_characters`: Character limit for text answers
- `min_selections`: Integer, minimum required selections (for multiple choice)
- `max_selections`: Integer, maximum allowed selections (null = unlimited)
- `allow_other`: Boolean, allow "Other" option with text input
- `randomize_options`: Boolean, randomize option display order
- `validation_rules`: JSON for custom validation
- `placeholder_text`: Input placeholder
- `help_text`: Additional help text
- `created_at`, `updated_at`: Timestamps

#### options
Answer options for choice-based questions with enhanced functionality.
- `id` (PK): Unique identifier
- `question_id` (FK): Reference to questions
- `option_text`: Display text
- `option_value`: Stored value
- `order_position`: Position among options
- `is_other`: Boolean, marks this as "Other" option requiring text input
- `is_exclusive`: Boolean, if selected deselects all other options ("None of the above")
- `is_active`: Boolean, if option is currently available
- `created_at`, `updated_at`: Timestamps

#### participants
Email-based duplicate prevention and completion tracking.
- `id` (PK): Unique identifier
- `survey_id` (FK): Reference to surveys
- `email`: Email address of participant (from external platform)
- `status`: Enum (invited, completed) - simplified two-state tracking
- `completed_at`: When survey was completed
- `created_at`, `updated_at`: Timestamps
- **Unique Index**: `[survey_id, email]` - prevents duplicate responses per survey

#### responses
Complete user submission to a survey.
- `id` (PK): Unique identifier
- `survey_id` (FK): Reference to surveys
- `participant_id` (FK): Reference to participants
- `completed_at`: When response was submitted
- `created_at`, `updated_at`: Timestamps

#### answers
Individual answers to survey questions with multiple choice support.
- `id` (PK): Unique identifier
- `response_id` (FK): Reference to responses
- `question_id` (FK): Reference to questions (updated from survey_questions)
- `text_answer`: Text response
- `numeric_answer`: Integer response
- `decimal_answer`: Decimal/float response
- `boolean_answer`: Boolean response
- `other_text`: Text input when "Other" option is selected
- `selection_count`: Cached count of selected options (for performance)
- `answered_at`: When question was answered
- `created_at`, `updated_at`: Timestamps

#### answer_options
Junction table for multiple choice selections.
- `id` (PK): Unique identifier
- `answer_id` (FK): Reference to answers
- `option_id` (FK): Reference to options
- `created_at`, `updated_at`: Timestamps

#### settings
Key-value settings for surveys.
- `id` (PK): Unique identifier
- `survey_id` (FK): Reference to surveys
- `setting_key`: Setting name/key
- `setting_value`: Setting value
- `created_at`, `updated_at`: Timestamps

### Key Relationships
- surveys → questions (one-to-many)
- surveys → participants (one-to-many)  
- surveys → settings (one-to-many)
- questions → options (one-to-many)
- questions ← question_types (many-to-one)
- participants → responses (one-to-one) - simplified: each participant answers once
- responses → answers (one-to-many)
- answers ← answer_options → options (many-to-many)

### Survey Response Flow
This engine uses a simplified approach for email-based duplicate prevention:

1. **Survey Access**: User clicks survey link with email parameter from external platform
2. **Duplicate Check**: System checks if participant record exists for [survey_id, email] combination
3. **Already Completed**: If participant exists with status 'completed' → show "already completed" message
4. **New Participant**: If no participant record → create participant with status 'invited' and email
5. **Survey Completion**: When user submits survey → update participant status to 'completed' + create response record
6. **One Response Per Email**: Unique index on [survey_id, email] prevents duplicate responses

**Key Features:**
- Email-based duplicate prevention (one response per email per survey)
- Simple two-state tracking (invited → completed)
- No session management or resume capability
- Direct integration with external platform emails

### Multiple Choice Question Patterns

#### Single Choice (Radio Buttons)
```ruby
# Question setup
question_type: "single_choice"
min_selections: 1
max_selections: 1
allow_other: false  # or true if "Other" option needed

# Answer storage
# - One record in question_answers
# - One record in question_answer_options (linking to selected option)
# - If allow_other=true and "Other" selected: populate other_text field
```

#### Multiple Choice (Checkboxes)
```ruby
# Question setup
question_type: "multiple_choice"
min_selections: 0      # or 1 if at least one required
max_selections: null   # or specific limit like 3
allow_other: true      # Allow custom "Other" option

# Answer storage
# - One record in question_answers
# - Multiple records in question_answer_options (one per selected option)
# - selection_count cached for performance
# - other_text populated if "Other" option selected
```

#### With Exclusive Options
```ruby
# Option setup (e.g., "None of the above") 
option.is_exclusive = true

# Logic: If exclusive option selected, all other selections are cleared
# If any other option selected, exclusive option is cleared
```

#### With Skip Logic
```ruby
# Option with conditional branching
option.skip_logic = {
  "action": "skip_to_question",
  "target_question_id": 15,
  "condition": "selected"
}

# When this option is selected, survey jumps to question 15
```

### Validation Rules Examples

#### Multiple Choice Validation
```ruby
survey_question.validation_rules = {
  "min_selections": 2,
  "max_selections": 4,
  "required_together": [option_id_1, option_id_2],  # If one selected, other required
  "mutually_exclusive": [option_id_3, option_id_4]  # Cannot select both
}
```

### Required Indexes
```sql
-- Performance-critical indexes
CREATE INDEX idx_questions_survey_order ON questions(survey_id, order_position);
CREATE INDEX idx_options_question_order ON options(question_id, order_position);
CREATE INDEX idx_answers_response_question ON answers(response_id, question_id);
CREATE INDEX idx_responses_survey_completed ON responses(survey_id, completed_at);
CREATE INDEX idx_settings_survey_key ON settings(survey_id, setting_key);
CREATE INDEX idx_participants_status ON participants(survey_id, status);
CREATE INDEX idx_answer_options_answer ON answer_options(answer_id);
CREATE INDEX idx_answer_options_selected_at ON answer_options(selected_at);
```

### Database Constraints (NOT NULL)

#### surveys
**Required (NOT NULL):**
- `id`, `title`, `is_active`, `global`, `status`, `created_at`, `updated_at`

**Optional (CAN BE NULL):**
- `description`, `published_at`, `expires_at`

#### question_types
**Required (NOT NULL):**
- `id`, `name`, `allows_options`, `allows_multiple_selections`, `created_at`

**Optional (CAN BE NULL):**
- `description`

#### questions
**Required (NOT NULL):**
- `id`, `survey_id`, `question_type_id`, `title`, `is_required`, `order_position`, `allow_other`, `randomize_options`, `created_at`, `updated_at`

**Optional (CAN BE NULL):**
- `description`, `scale_min`, `scale_max`, `scale_min_label`, `scale_max_label`, `max_characters`, `min_selections`, `max_selections`, `validation_rules`, `placeholder_text`, `help_text`

#### options
**Required (NOT NULL):**
- `id`, `question_id`, `option_text`, `option_value`, `order_position`, `is_other`, `is_exclusive`, `is_active`, `created_at`, `updated_at`

**Optional (CAN BE NULL):**
- `skip_logic`

#### participants
**Required (NOT NULL):**
- `id`, `survey_id`, `status`, `created_at`, `updated_at`

**Optional (CAN BE NULL):**
- `user_id`, `participant_identifier`, `invited_at`, `started_at`, `completed_at`, `last_activity_at`

#### responses
**Required (NOT NULL):**
- `id`, `survey_id`, `survey_participant_id`, `is_completed`, `created_at`, `updated_at`

**Optional (CAN BE NULL):**
- `started_at`, `completed_at`

#### answers
**Required (NOT NULL):**
- `id`, `survey_response_id`, `survey_question_id`, `selection_count`

**Optional (CAN BE NULL):**
- `text_answer`, `numeric_answer`, `decimal_answer`, `boolean_answer`, `other_text`, `answered_at`

#### answer_options
**Required (NOT NULL):**
- `id`, `question_answer_id`, `question_option_id`, `selected_at`

**Optional (CAN BE NULL):**
- `selection_order`

#### settings
**Required (NOT NULL):**
- `id`, `survey_id`, `setting_key`, `setting_value`, `created_at`, `updated_at`

### Application Requirements

#### Localization
- **Primary Language**: Spanish (es)
- All user-facing labels, messages, and content should be in Spanish
- Database content (survey titles, questions, options) can be in Spanish
- No multi-language support needed initially

#### Features NOT Required
- Real-time/WebSocket functionality
- File upload questions
- Multi-tenancy (initially)

### Model Development Strategy

#### Table Naming Convention
All models will use the `table_name_prefix` to namespace tables:
```ruby
# In each model class
def self.table_name_prefix
  "survey_engine_"
end
```

**Final Table Names:**
- `survey_engine_surveys`
- `survey_engine_question_types`
- `survey_engine_questions`  
- `survey_engine_options`
- `survey_engine_participants`
- `survey_engine_responses`
- `survey_engine_answers`
- `survey_engine_answer_options`
- `survey_engine_settings`

This prevents naming conflicts with host application tables.

#### Phase 1: Core Models (Build First)
1. `SurveyEngine::QuestionType` - Seed with standard question types
2. `SurveyEngine::Survey` - Main survey entity
3. `SurveyEngine::Question` - Questions within surveys  
4. `SurveyEngine::Option` - Choice options for questions

#### Phase 2: Response System (Build Second)
5. `SurveyEngine::Participant` - Participant tracking
6. `SurveyEngine::Response` - Response sessions
7. `SurveyEngine::Answer` - Individual question answers
8. `SurveyEngine::AnswerOption` - Multiple choice selections

#### Phase 3: Configuration (Build Last)  
9. `SurveyEngine::Setting` - Survey-specific settings

### Survey Settings (Initial Implementation)

Focus on essential limits and thresholds only:

#### Response Limits
```ruby
"max_responses" => "1000"           # Maximum total responses allowed
"max_responses_per_user" => "1"     # Responses per participant (0 = unlimited)
"response_time_limit" => "30"       # Minutes to complete survey (0 = no limit)
```

#### Completion Requirements  
```ruby
"required_completion_percentage" => "80"  # % of required questions to mark complete
"min_questions_answered" => "5"           # Minimum questions that must be answered
```

#### Session Management
```ruby
"session_timeout" => "60"           # Minutes before session expires (0 = no timeout)
"auto_save_frequency" => "30"       # Seconds between auto-saves (0 = disabled)
```

#### Data Retention
```ruby
"data_retention_days" => "365"      # Days to keep response data (0 = forever)
```

**Setting Value Types:**
- All values stored as strings in `setting_value` column
- Convert to appropriate types in model methods
- Use `"0"` to indicate "unlimited" or "disabled" for numeric limits