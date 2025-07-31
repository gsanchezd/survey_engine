# SurveyEngine Routes
# Add these routes to your config/routes.rb file

# Mount the SurveyEngine (required)
mount SurveyEngine::Engine => "/surveys"

# Optional: Override engine routes with custom controller
# Uncomment if you want to use a custom SurveysController
# resources :surveys, only: [:index, :show] do
#   member do
#     get :answer
#     post :submit_answer
#     get :completed  
#     get :results
#   end
# end

# Optional: Set surveys as root path
# root "survey_engine/surveys#index"