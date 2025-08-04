# Survey Results System - Planning Document

## Overview
Design a comprehensive survey results system that handles complex business logic for question visibility, data aggregation, and presentation without reinventing the wheel for different use cases (downloads, displays, panels, etc.).

## Core Challenges

### 1. Question Visibility Logic
- **Matrix Questions**: Parent questions are not directly answerable, only sub-questions are
- **Conditional Questions**: Only visible based on previous answers (single/range conditions)
- **Question Ordering**: Dynamic numbering that excludes hidden questions
- **Mixed Question Types**: Text, scale, multiple choice, matrix, etc.

### 2. Current Business Logic Locations
- `Response#visible_questions_for_response` - Determines which questions were visible to a specific respondent
- `Response#completion_percentage` - Calculates completion based on visible questions only
- `ConditionalFlowHelper` - Handles dynamic question numbering and visibility
- Matrix question rendering logic in views

## Proposed Architecture (CSV-First Approach)

### 1. Simplified Service Layer
Focus on CSV export with potential for extension:

```ruby
# Main CSV exporter service
SurveyEngine::CsvExporter
  - initialize(survey_or_template)
  - generate_headers
  - generate_rows
  - to_csv
  
# Support services
SurveyEngine::ResponseFlattener
  - flatten_response(response)
  - handle_matrix_questions(response, question)
  - handle_conditional_visibility(response, question)
  
# Question visibility service (extract from Response model)
SurveyEngine::QuestionVisibilityService
  - visible_questions_for(response)
  - all_possible_questions(survey)
  - question_was_shown?(response, question)
```

### 2. Results Data Structure
Standardized data format that all consumers can use:

```ruby
{
  survey: {
    id: 1,
    title: "Survey Title",
    total_responses: 150,
    completion_rate: 85.5
  },
  questions: [
    {
      id: 1,
      title: "Question Title",
      type: "single_choice",
      visible_to_count: 150,
      response_count: 145,
      response_rate: 96.7,
      data: {
        # Question-type specific aggregated data
      },
      raw_responses: [
        # Individual response data when needed
      ]
    }
  ]
}
```

### 3. Consumer Interfaces
Engine provides data, host app handles presentation:

```ruby
# In Survey Engine (this gem)
SurveyEngine::CsvExporter  # CSV export functionality
SurveyEngine::ResultsService  # Service to fetch structured results data

# In Host Application (with ActiveAdmin)
# Host app will create its own ActiveAdmin resources using:
#   - SurveyEngine::Survey.all
#   - SurveyEngine::Response.includes(:answers)
#   - SurveyEngine::ResultsService.new(survey).aggregate_data
#   - SurveyEngine::CsvExporter.new(survey).to_csv
```

## Implementation Strategy

### Phase 1: CSV Export Foundation
1. **Create CSV-focused processor**
   - Flatten hierarchical data for CSV format
   - Handle matrix questions as separate rows
   - Include/exclude conditional questions based on visibility

2. **CSV Data Structure**
   ```csv
   Response ID, Email, Completed At, Question 1, Question 2, Matrix Q1 Row 1, Matrix Q1 Row 2, ...
   1, user@example.com, 2024-01-15, "Answer 1", "Answer 2", "Option A", "Option B", ...
   ```

3. **Special Cases for CSV**
   - Matrix questions: Each sub-question becomes a column
   - Multiple choice: Comma-separated values or separate columns
   - Conditional questions: Empty cells when not shown
   - Include a "Questions Asked" column to track conditional visibility

### Phase 2: Results Service for Host Apps
1. **Create ResultsService that returns structured data**
   - Response counts and completion rates
   - Per-question statistics
   - Properly handles visibility logic
   - Returns data that host app's ActiveAdmin can easily display
   
2. **Ensure models are ActiveAdmin-friendly**
   - Proper associations for eager loading
   - Scopes for filtering (completed, by_date, etc.)
   - Methods that ActiveAdmin can use directly

### Phase 3: Future Enhancements (If Needed)
1. **Only if specifically requested later**
   - Additional export formats
   - Advanced filtering
   - Analytics dashboards

## Key Design Principles

### 1. Single Source of Truth
- All visibility logic centralized in one place
- No duplication of conditional evaluation
- Consistent question ordering across all consumers

### 2. Question Type Agnostic
- Base interfaces that work for all question types
- Extensible for new question types
- Type-specific processing when needed

### 3. Performance Focused
- Eager loading strategies for large datasets
- Caching for expensive calculations
- Lazy loading for detailed breakdowns

### 4. Configurable Output
```ruby
# Example usage
results = SurveyEngine::Results::ProcessorService.new(survey)
  .include_raw_responses(false)
  .group_by(:demographics)
  .filter_by(completed: true)
  .process

# Export to different formats
results.export_to(:csv, filename: 'survey_results.csv')
results.export_to(:pdf, template: 'detailed_report')

# Present in web interface
presenter = SurveyEngine::Results::Presenters::ChartPresenter.new(results)
presenter.render_question(question_id: 5, chart_type: 'bar')
```

## Benefits of This Approach

1. **DRY Principle**: Write visibility logic once, use everywhere
2. **Consistency**: Same results whether viewing, downloading, or analyzing
3. **Extensibility**: Easy to add new export formats or presentation styles
4. **Performance**: Optimized queries and caching strategies
5. **Maintainability**: Centralized business logic, easier testing
6. **Flexibility**: Different consumers can request different levels of detail

## Questions to Resolve Before Implementation

### Technical Decisions
1. **Caching Strategy**: Where and how long to cache aggregated results?
   - Redis? Database cache table? In-memory?
   - Cache invalidation triggers?

2. **Large Datasets**: Pagination/streaming for surveys with thousands of responses?
   - Batch processing size?
   - Background jobs for large exports?

3. **Historical Data**: How to handle results when survey structure changes?
   - Version survey templates?
   - Snapshot questions at response time?

### Business Requirements
1. **Export Format**: 
   - CSV only (confirmed priority)
   - No Excel formatting, PDF, or JSON API needed

2. **Results Granularity**: What level of detail is needed?
   - Individual responses always available?
   - Anonymized vs identified responses?
   - Time-based aggregations (daily, weekly)?

3. **Real-time Requirements**: 
   - Live updating dashboard needed?
   - Or batch processing acceptable?

4. **Permission Levels**: Who can access what?
   - Public results summary?
   - Admin full access?
   - Respondent can see own response?

### Data Handling
1. **Empty/Partial Responses**: How to handle?
   - Include partially completed responses?
   - Show separate stats for completed vs all?

2. **Matrix Questions Special Cases**:
   - Aggregate by row, column, or both?
   - How to represent in flat formats like CSV?

3. **Conditional Question Reporting**:
   - Show all questions or only those that were visible?
   - How to indicate why a question was/wasn't shown?

### UI/UX Considerations
1. **Results Dashboard Features**:
   - Filter by date range?
   - Filter by participant attributes?
   - Compare multiple surveys?

2. **Export Options**:
   - Include metadata (survey info, export date)?
   - Custom column mapping for CSV?
   - Formatting preferences?

## CSV Export Examples

### Standard Survey CSV Output
```csv
Response ID,Email,Started At,Completed At,Completion %,Q1: How satisfied are you?,Q2: Comments,Q3: Choose options,Matrix: Service - Speed,Matrix: Service - Quality
1,user1@example.com,2024-01-15 10:00,2024-01-15 10:15,100,Very Satisfied,"Great service","Option A, Option B",Excellent,Good
2,user2@example.com,2024-01-15 11:00,2024-01-15 11:10,100,Satisfied,"","Option A",Good,Excellent
3,user3@example.com,2024-01-15 12:00,,50,Neutral,"","","",""
```

### With Conditional Questions
```csv
Response ID,Email,Q1: NPS Score,Q2: Why that score? (shown if <=6),Q3: What did you like? (shown if >=9)
1,user1@example.com,3,"Poor service",""
2,user2@example.com,9,"","Excellent support"
3,user3@example.com,7,"",""
```

## Host Application Integration Example

### ActiveAdmin Resource in Host App
```ruby
# app/admin/survey_results.rb (in host application)
ActiveAdmin.register_page "Survey Results" do
  content do
    survey = SurveyEngine::Survey.find(params[:survey_id])
    results = SurveyEngine::ResultsService.new(survey)
    
    # Summary panel
    panel "Survey: #{survey.title}" do
      div "Total Responses: #{results.response_count}"
      div "Completion Rate: #{results.completion_rate}%"
    end
    
    # Per-question breakdown
    panel "Results by Question" do
      table_for results.question_statistics do
        column :question_title
        column :response_count
        column :response_rate
        column :average_score  # for scale questions
      end
    end
    
    # Export action
    action_item :export_csv do
      link_to "Export CSV", export_csv_path(survey_id: survey.id)
    end
  end
  
  controller do
    def export_csv
      survey = SurveyEngine::Survey.find(params[:survey_id])
      csv_data = SurveyEngine::CsvExporter.new(survey).to_csv
      send_data csv_data, filename: "survey_#{survey.id}_results.csv"
    end
  end
end
```

## Next Steps

1. **Build CsvExporter service** with basic functionality
2. **Create ResultsService** that returns structured data for host apps
3. **Extract visibility logic** from Response model to QuestionVisibilityService
4. **Add useful scopes and methods** to models for ActiveAdmin integration
5. **Handle matrix questions** properly in both CSV and ResultsService
6. **Document integration** for host applications