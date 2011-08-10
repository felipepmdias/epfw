require 'test_helper'

class OtherControllerTest < ActionController::TestCase
  
  def setup
    #logger.debug "Test Case: #{name}"  
    @controller = OtherController.new
    #@request    = ActionController::TestRequest.new
    #@response   = ActionController::TestResponse.new
    #@oup_20060721 = create_oup_20060721
    #@oup_20060728 = create_oup_20060728
    #@oup_wiki = create_oup_wiki(@oup_20060721)
    #@andy = users(:andy) # admin
    #@george = users(:george) # central admin
    #@tony = users(:tony) # user
    #@cash = users(:cash) 
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
  
end
