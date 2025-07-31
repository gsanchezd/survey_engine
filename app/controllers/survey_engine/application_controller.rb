module SurveyEngine
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    # Ensure main app helpers are available
    helper ::ApplicationHelper if defined?(::ApplicationHelper)

    # Use the main application's alpha layout to maintain theme consistency
  end
end
