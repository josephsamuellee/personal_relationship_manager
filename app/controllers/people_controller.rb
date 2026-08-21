class PeopleController < ApplicationController
  before_action :set_person, only: [ :show, :update ]

  def index
    @people = Person.ordered_by_name
  end

  def show
    prepare_person_page
    @favorite_slot = Setting.favorite_slot_for(@person)
  end

  def update
    success = false
    favorite_error = nil

    ActiveRecord::Base.transaction do
      unless @person.update(person_params)
        raise ActiveRecord::Rollback
      end

      if favorite_slot_submitted?
        begin
          Setting.assign_favorite_slot!(@person, favorite_slot_param)
        rescue ArgumentError => e
          favorite_error = e.message
          raise ActiveRecord::Rollback
        end
      end

      success = true
    end

    if success
      redirect_to person_path(@person), notice: "About section updated."
    else
      @person.errors.add(:base, favorite_error) if favorite_error
      prepare_person_page
      @favorite_slot = favorite_slot_param
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def prepare_person_page
    @entries = @person.entries.includes(:primary_person, :tags).recent_first
    @recent_entries = @entries.limit(5)
    @timeline_entries = @entries.chronological
  end

  def person_params
    params.require(:person).permit(:about_markdown)
  end

  def favorite_slot_submitted?
    params[:person]&.key?(:favorite_slot)
  end

  def favorite_slot_param
    params[:person][:favorite_slot]
  end
end
