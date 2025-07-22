SurveyEngine::Engine.routes.draw do
  root 'surveys#index'
  resources :surveys, only: [:index, :show], path: ''
end
