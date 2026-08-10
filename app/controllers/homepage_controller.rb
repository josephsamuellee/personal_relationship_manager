class HomepageController < ApplicationController
  def show
    @presenter = HomepagePresenter.new
    @calendar = CalendarProvider.current
  end
end
