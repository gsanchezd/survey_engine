Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/surveys"

  # Root route
  root "survey_engine/surveys#index"
end
