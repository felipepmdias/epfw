require 'test_helper'

class EpfcLibraryTest < ActiveSupport::TestCase
  
  # running tests on Windows requires UnxUtils, please see the README_FOR_APP.
  # This test causes a runtime error if unzip is not installed
  test "Unzip" do
    cmd = IO.popen('unzip -version', "w+")
    cmd.close_write
  end
end
