class PeopleController < ApplicationController
  before_action :set_person, only: [:show, :update]

  def index
    @people = Person.ordered_by_name
  end

  def show
    @entries = @person.entries.includes(:primary_person, :tags).recent_first
    @recent_entries = @entries.limit(5)
    @timeline_entries = @entries.chronological
  end

  def update
    if @person.update(person_params)
      redirect_to person_path(@person), notice: "About section updated."
    else
      @entries = @person.entries.includes(:primary_person, :tags).recent_first
      @recent_entries = @entries.limit(5)
      @timeline_entries = @entries.chronological
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(:about_markdown)
  end
end
