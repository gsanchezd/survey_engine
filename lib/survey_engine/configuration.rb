module SurveyEngine
  class Configuration
    attr_accessor :current_user_email_method, :require_manual_email
    
    def initialize
      @current_user_email_method = :current_user_email
      @require_manual_email = false
    end
    
    # Allow callable objects for more complex email resolution
    def current_user_email_callable
      if @current_user_email_method.respond_to?(:call)
        @current_user_email_method
      else
        -> { send(@current_user_email_method) }
      end
    end
  end
end