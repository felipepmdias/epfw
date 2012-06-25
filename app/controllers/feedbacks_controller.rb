# Feedback is created in the portal by authenticated and anonymous users, 
# see OtherController.feedback. This controller together with SitesController
# is used to manage feedback, see SitesController.feedback

class FeedbacksController < ApplicationController

  layout 'management'
  
  before_filter :authenticate_cadmin
  
  protect_from_forgery :except => [:destroy] # workaround for ActionController::InvalidAuthenticityToken

  def edit
    @feedback = Feedback.find(params[:id])
  end
  
  def update
    @feedback = Feedback.find(params[:id])
    if @feedback.update_attributes(params[:feedback])
      flash[:notice] = 'Feedback was successfully updated.'
      redirect_to @feedback.request_referer
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Feedback.find(params[:id]).destroy
    redirect_to :back
  end
  
end
