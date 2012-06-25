require 'test_helper'

class OtherControllerTest < ActionController::TestCase
  
  def setup
    @controller = OtherController.new
  end
  
  def teardown
    [ENV['EPFWIKI_SITES_PATH'], ENV['EPFWIKI_WIKIS_PATH']].each do |p|
      FileUtils.rm_r(p) if File.exists?(p)
      FileUtils.makedirs(p)
    end
  end  

  # Shows all users can access information about the application with other/about
  test "About" do
    get :about
    assert_response :success
  end
  
  # Shows that also for logged on users
  test "About2" do
    george = Factory(:user, :name => 'George Shapiro', :password => 'secret', :admin => 'C')
    assert_not_nil george
    session['user'] = george.id
    get :about
    assert_response :success
  end
  
end
