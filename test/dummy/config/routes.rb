Rails.application.routes.draw do
  mount SurveyEngine::Engine => "/survey_engine"
  
  # Survey routes
  resources :surveys, only: [:index, :show] do
    member do
      post :start
      get :answer
      post :submit_answer
      get :completed
      get :results
    end
  end
  
  # Root route
  root "surveys#index"
end
