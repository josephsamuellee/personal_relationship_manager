require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "missing setting falls back to dark" do
    assert_equal 0, Setting.count
    assert_equal "dark", Setting.current_theme
  end

  test "invalid stored theme falls back to dark" do
    setting = Setting.create!(theme: "light")
    setting.update_column(:theme, "neon")

    assert_equal "dark", Setting.current_theme
  end

  test "blank stored theme falls back to dark" do
    setting = Setting.create!(theme: "light")
    setting.update_column(:theme, "")

    assert_equal "dark", Setting.current_theme
  end

  test "update_theme persists light and dark" do
    Setting.update_theme("light")
    assert_equal "light", Setting.first.theme
    assert_equal "light", Setting.current_theme

    Setting.update_theme("dark")
    assert_equal "dark", Setting.first.theme
    assert_equal "dark", Setting.current_theme
  end

  test "update_theme ignores invalid values" do
    Setting.update_theme("light")
    Setting.update_theme("neon")

    assert_equal "light", Setting.current_theme
  end
end
