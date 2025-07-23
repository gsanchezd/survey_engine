SurveyEngine::Engine.routes.draw do
  root "surveys#index"
  resources :surveys, only: [ :index, :show ], path: "" do
    member do
      post :start
      get :answer
      post :submit_answer
      get :completed
      get :results
    end
  end
end
