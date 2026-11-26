# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.20] - 2026-11-25

### Changed
- Ruby 3.4.13 de verdad en local y en el CI. La subida anterior cambió solo `.ruby-version`, pero
  mise lee primero `mise.toml`, que seguía en 3.4.4: el parche de seguridad nunca se aplicó en
  local, y el CI corría con 3.3.2. Ahora el CI lee `.ruby-version` y la versión vive en dos
  archivos, que hay que cambiar juntos (ver `AGENTS.md`).
- Rails 8.1.4.1 (desde 8.0.5.2), la misma versión de empieza2. El gemspec ya aceptaba
  `rails >= 7.1.0`; lo que lo frenaba era el `"~> 8.0.2"` del `Gemfile` de la dummy.
- Las gemas de desarrollo y test con avisos de seguridad, que las apps que instalan la gema no
  heredan: Puma 6.6.0 → 8.1.3 y sqlite3 2.7.3 → 2.10.2 (bundler-audit marcaba los dos lockfiles), y
  Devise 4.9.4 → 5.0.4, que pasa las opciones de rutas como keywords. La 4.9.4 llamaba a
  `resource :registration, options` con un hash suelto, deprecado en Rails 8.1, y el aviso apuntaba
  a `devise_for :users` de la dummy aunque el problema estaba dentro de Devise.
- Se saca `rails/tasks/statistics.rake` del `Rakefile`, deprecado en 8.1 sin reemplazo.
- `AGENTS.md` nuevo, adaptado del de empieza2: flujo de ramas, bump de versión y las revisiones
  antes de pushear. Incluye la trampa del bump: los dos `Gemfile.lock` guardan la versión de la
  gema, y después de 0.1.19 el de la dummy siguió diciendo 0.1.18.

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