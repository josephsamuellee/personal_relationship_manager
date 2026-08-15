class ConfigController < ApplicationController
  def show
    @theme = Setting.current_theme
    @statistics = ServerStatistics.new
  end

  def update
    Setting.update_theme(params[:theme])
    redirect_to config_path
  end
end
