module SurveyEngine
  module ApplicationHelper
    include ConditionalFlowHelper
    def time_duration_in_words(seconds)
      return "0 seconds" if seconds.nil? || seconds <= 0
      
      minutes = seconds / 60
      remaining_seconds = seconds % 60
      
      if minutes >= 60
        hours = minutes / 60
        remaining_minutes = minutes % 60
        
        parts = []
        parts << "#{hours} hour#{'s' if hours != 1}" if hours > 0
        parts << "#{remaining_minutes} minute#{'s' if remaining_minutes != 1}" if remaining_minutes > 0
        parts << "#{remaining_seconds} second#{'s' if remaining_seconds != 1}" if remaining_seconds > 0 && hours == 0
        
        parts.join(", ")
      elsif minutes > 0
        parts = []
        parts << "#{minutes} minute#{'s' if minutes != 1}"
        parts << "#{remaining_seconds} second#{'s' if remaining_seconds != 1}" if remaining_seconds > 0
        
        parts.join(", ")
      else
        "#{seconds} second#{'s' if seconds != 1}"
      end
    end
  end
end
