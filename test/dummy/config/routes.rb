Rails.application.routes.draw do
  devise_for :users
  mount SurveyEngine::Engine => "/surveys"

  # Root route
  root "survey_engine/surveys#index"
end
