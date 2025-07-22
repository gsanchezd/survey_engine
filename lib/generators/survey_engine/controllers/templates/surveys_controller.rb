module SurveyEngine
  class SurveysController < ApplicationController
    def index
      @surveys = Survey.published.active
    end

    def show
      @survey = Survey.find_by!(uuid: params[:id])
      redirect_to root_path unless @survey.can_receive_responses?
    end
  end
end