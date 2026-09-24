require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  # Let click_button / fill_in find elements by their aria-label (e.g. the icon-only eye button)
  Capybara.enable_aria_label = true
end
