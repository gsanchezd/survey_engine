module ApplicationHelper
  include SurveyEngine::ConditionalFlowHelper

  def time_duration_in_words(seconds)
    return "0 seconds" unless seconds&.positive?

    if seconds < 60
      "#{seconds.round} seconds"
    elsif seconds < 3600
      "#{(seconds / 60).round} minutes"
    else
      hours = (seconds / 3600).round(1)
      "#{hours} hour#{'s' if hours != 1}"
    end
  end
end
