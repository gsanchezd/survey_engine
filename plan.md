# Survey Engine Development Plan

## Remaining Features

### 1. Add Range Conditional Logic for NPS Passives (7-8)

**Problem:** Cannot handle NPS Passives (score 7-8) - need range conditions  
**Current limitation:** Only single condition operators (`>=`, `<=`, `==`, etc.)  
**Needed:** Multiple conditions with AND/OR logic

**Implementation:**
- Add database fields for second condition
- Update Question model with complex condition evaluation
- Add validation for complex conditions
- Create tests for range logic

**Files to Modify:**
- `db/migrate/add_range_conditional_logic_to_questions.rb`
- `app/models/survey_engine/question.rb`
- `test/models/survey_engine/question_test.rb`

**Priority:** High (completes NPS survey functionality)

