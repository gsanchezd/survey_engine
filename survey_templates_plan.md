# Implementation Plan: Survey Templates Migration

## Executive Summary

This document outlines the plan to complete the migration of the survey system to a template-based architecture. Models and migrations are already implemented; now we need to update controllers and views.

## Current Status

### ✅ Completed
- **Migrations**: `survey_engine_survey_templates` table created
- **Models**: 
  - `SurveyTemplate` implemented with associations
  - `Survey` updated to belong to template
  - `Question` now belongs to template instead of survey
- **Database**: Restructured with new architecture

### ❌ Pending
- **Controllers**: References to removed fields cause errors
- **Views**: Multiple references to non-existent fields

## Critical Issues Identified

1. **SurveysController** (lines 4, 15, 22): References to removed `status` and `description`
2. **surveys/index.html.erb** (lines 17, 22): Fields `description` and `status` don't exist
3. **surveys/show.html.erb** (lines 8, 15): Same missing fields

## Detailed Implementation Plan

### 🔴 Phase 1: Critical Fixes (High Priority)

#### 1.1 Fix SurveysController
**File**: `app/controllers/survey_engine/surveys_controller.rb`
- Remove `Survey.published` scope (line 4)
- Remove references to `@survey.status` (lines 15, 22)
- Implement new filtering logic if needed

#### 1.2 Update surveys/index View
**File**: `app/views/survey_engine/surveys/index.html.erb`
- Remove description column (line 17)
- Remove status column (line 22)
- Add associated template information
- Show template name and question count

#### 1.3 Update surveys/show View
**File**: `app/views/survey_engine/surveys/show.html.erb`
- Remove description section (line 8)
- Remove status badge (line 15)
- Add template information section
- Show details of template used
```

