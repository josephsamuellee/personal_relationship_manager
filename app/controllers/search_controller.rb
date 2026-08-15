class SearchController < ApplicationController
  def show
    @query = params[:q].to_s
    @results = SearchService.new(@query).results
  end

  def entries
    @query = params[:q].to_s
    @entries = SearchService.new(@query).all_entries
  end
end
