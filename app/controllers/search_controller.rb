class SearchController < ApplicationController
  def show
    @query = params[:q].to_s
    @results = SearchService.new(@query).results
  end
end
