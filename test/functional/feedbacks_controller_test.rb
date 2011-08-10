require 'test_helper'

class FeedbacksControllerTest < ActionController::TestCase

  def setup
    #logger.debug "Test Case: #{name}"  
    @controller = FeedbacksController.new
    #@request    = ActionController::TestRequest.new
    #@response   = ActionController::TestResponse.new
    #@andy = users(:andy) # admin
    #@george = users(:george) # central admin
    #@tony = users(:tony) # user
    #@emails = ActionMailer::Base::deliveries
    #@emails.clear
    @george = Factory(:user, :name => 'George Shapiro', :password => 'secret', :admin => 'C')
    @andy = Factory(:user, :name => 'Andy Kaufman', :password => 'secret', :admin => 'Y')
    @cash = Factory(:user, :name => 'Cash Oshman', :password => 'secret', :admin => 'N')
    @tony = Factory(:user, :name => 'Tony Clifton', :password => 'secret', :admin => 'N')
  end

  test "Edit feedback"  do
    get :edit, :id => 999
    assert_unot_cadmin_message
  end

  test "Destroy feedback" do 
    feedback = Feedback.create(:email => 'x@adb.com',:text => 'test_show')
    #get :index # TODO MOETWEB
    session['user'] = @andy
    assert_nothing_raised {Feedback.find(feedback.id)}

    post :destroy, :id => feedback.id
    assert_unot_cadmin_message
    
    # TODO cannot test this because the controller uses request.referer
    session['user'] = @george
    post :destroy, :id => feedback.id
    
    assert_response :redirect
    assert_redirected_to '/'#:action => 'list' # bestaat niet, hoe heeft dit ooit gewerk

    assert_raise(ActiveRecord::RecordNotFound) {Feedback.find(feedback.id)}
  end
end
