require "test_helper"

class HomepageControllerTest < ActionDispatch::IntegrationTest
  test "homepage contains a config link at the bottom of page content" do
    get homepage_path

    assert_response :success
    assert_select ".floating-nav-top a", text: "Config", count: 0
    assert_select ".homepage-config-link a[href=?]", config_path, text: "Config"

    html = Nokogiri::HTML(response.body)
    last_homepage_content = html.at_css(".homepage > *:last-child")
    assert_equal "homepage-config-link", last_homepage_content["class"]
  end
end
