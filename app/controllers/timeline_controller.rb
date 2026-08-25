class TimelineController < ApplicationController
  def show
    today = Time.zone.today
    available = TimelinePresenter.available_years
    resolved = TimelinePresenter.parse_year(params[:year], today: today, available: available)
    requested = Integer(params[:year], exception: false)

    if requested != resolved
      redirect_to timeline_path(year: resolved)
      return
    end

    @presenter = TimelinePresenter.new(
      year: resolved,
      today: today,
      available_years: available
    )
  end
end
