class HomepageController < ApplicationController
  def show
    @presenter = HomepagePresenter.new
    @upcoming_calendar = UpcomingCalendarPresenter.new
  end
end
