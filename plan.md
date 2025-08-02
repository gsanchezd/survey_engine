# Survey Engine Development Plan

## Remaining Features

### 1. Fix Survey Access Issue (URGENT)

**Problem:** Users getting "No tienes invitación para responder esta encuesta" even when invited
**Root Cause:** Email resolution relies on Devise authentication (`current_user.email`) but we're using URL parameters for invitation-based access

**Solution:**
- Update `resolve_participant_email` method to check URL parameters first
- Fallback to configured authentication method

**Files to Modify:**
- `app/controllers/survey_engine/surveys_controller.rb`

**Priority:** URGENT (blocks testing)

---

### 2. Add Range Conditional Logic for NPS Passives (7-8)

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

