Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/"
  
  # Root route
  root "survey_engine/surveys#index"
end
