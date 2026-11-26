# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.19] - 2026-11-25

### Fixed
- Las relaciones de `SurveyEngine::Question` consigo misma (`conditional_parent`,
  `conditional_questions`, `matrix_parent` y `matrix_sub_questions`) nombran la clase con su
  módulo (`class_name: "SurveyEngine::Question"`). Con `"Question"` a secas, Rails
  (`ActiveRecord::Reflection#_klass`) ve que es igual al nombre de la clase dueña sin el módulo y
  busca primero `::Question`: en una app con su propio modelo `Question` las relaciones apuntaban
  a ese modelo. En empieza2 (que tiene `Question` para sus quizzes) validar una fila de matriz
  reventaba (`NoMethodError: is_matrix_question?`) y la validación de las respuestas de matriz
  comparaba contra una pregunta de quiz. La app dummy no tiene `::Question`, por eso los tests no
  lo veían; `question_class_name_test.rb` define uno para reproducirlo.

## [0.1.0] - 2025-01-22

### Added
- Initial release of SurveyEngine Rails Engine
- Complete survey management system with email-based participants
- Support for multiple question types:
  - Text (free-form text input)
  - Scale (numeric rating scales with custom labels)
  - Number (numeric input)
  - Boolean (yes/no questions)
  - Single choice (radio button selections)
  - Multiple choice (checkbox selections)
  - "Other" option support with custom text input
- UUID-based survey routing for SEO-friendly URLs
- Comprehensive analytics and reporting system
- CSV and JSON export functionality
- Mobile-responsive views with zero JavaScript dependencies
- Views generator (`rails generate survey_engine:views`) for customization
- Vanilla CSS with CSS custom properties for easy theming
- Complete test suite with fixtures
- Comprehensive documentation with API examples

### Features
- **Survey Management**: Create, publish, pause, and archive surveys
- **Question Builder**: Dynamic question creation with ordering and validation
- **Response Tracking**: Email-based participant management with duplicate prevention  
- **Analytics**: Real-time completion rates, response analysis, and cross-survey comparison
- **Export**: CSV and JSON export with customizable formats
- **Customization**: Overrideable views and CSS for complete control over appearance
- **Rails Integration**: Full Rails Engine with proper namespace isolation

### Technical Details
- Rails 7.1+ compatibility
- Ruby 3.0+ requirement
- Database agnostic with proper migrations
- Engine-prefixed tables (`survey_engine_*`) to avoid conflicts
- UUID support for survey routing
- Comprehensive model validations and associations
- Scoped queries for efficient data retrieval

[0.1.0]: https://github.com/gonzalosanchez/survey_engine/releases/tag/v0.1.0