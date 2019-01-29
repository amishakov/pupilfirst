module Founders
  class DashboardController < ApplicationController
    before_action :authenticate_founder!
    before_action :skip_container

    # GET /founder/dashboard, GET /student/dashboard
    def dashboard
      # TODO: Add Pundit authorization.

      # Founders without proper startups will not have dashboards.
      raise_not_found if current_startup.blank?
    end

    # GET /founder/dashboard/targets/:id(/:slug), GET /student/dashboard/targets/:id(/:slug)
    def target_overlay
      # TODO: Add Pundit authorization

      dashboard

      @target = Target.find_by(id: params[:id])
      raise_not_found if @target.blank?

      render 'dashboard'
    end

    private

    def startup_is_admitted
      return if current_founder.blank?

      current_startup.present? && !current_startup.level_zero?
    end

    def skip_container
      @skip_container = true
    end
  end
end
