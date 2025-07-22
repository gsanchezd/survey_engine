Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/survey_engine"
end
