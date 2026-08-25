class TimelineController < ApplicationController
  def show
    today = Time.zone.today
    available = TimelinePresenter.available_years
    show_all = TimelinePresenter.show_all?(params[:show_all])
    resolved = TimelinePresenter.parse_year(params[:year], today: today)
    requested = Integer(params[:year], exception: false)

    if requested != resolved
      redirect_to timeline_path({ year: resolved }.merge(show_all ? { show_all: 1 } : {}))
      return
    end

    @presenter = TimelinePresenter.new(
      year: resolved,
      today: today,
      available_years: available,
      show_all: show_all
    )
  end
end
