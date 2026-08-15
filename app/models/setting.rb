class Setting < ApplicationRecord
  THEMES = %w[dark light].freeze
  DEFAULT_THEME = "dark".freeze

  validates :theme, inclusion: { in: THEMES }

  def self.current_theme
    value = first&.theme
    THEMES.include?(value) ? value : DEFAULT_THEME
  end

  def self.update_theme(value)
    normalized = value.to_s
    return current_theme unless THEMES.include?(normalized)

    record = first_or_initialize
    record.theme = normalized
    record.save!
    record.theme
  end
end
