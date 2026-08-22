require "turbo/system_test_helper"

# Turbo Stream broadcast test helpers.
#
# Unit/model/job specs assert broadcasts with assert_turbo_stream_broadcasts /
# capture_turbo_stream_broadcasts (Turbo::Broadcastable::TestHelper, which pulls
# in ActionCable::TestHelper and needs the :test cable adapter). Feature specs
# wait for the browser's cable sockets with connect_turbo_cable_stream_sources
# (Turbo::SystemTestHelper) before triggering a broadcast, so the swap is
# observed rather than raced.
RSpec.configure do |config|
  # The turbo capture/assert helpers call Minitest-style assertions internally
  # (assert_nothing_raised, assert_broadcasts), so their host assertions module
  # has to come along for the ride in these plain RSpec example groups.
  %i[model job channel].each do |type|
    config.include ActiveSupport::Testing::Assertions, type: type
    config.include Turbo::Broadcastable::TestHelper, type: type
  end
  config.include Turbo::SystemTestHelper, type: :feature
end
