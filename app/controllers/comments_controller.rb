class CommentsController < ApplicationController
  
  layout 'management'
  
  before_filter :authenticate_cadmin, :only => [:update, :destroy]
  
  cache_sweeper :sweeper, :only => [:update, :destroy]
    
  protect_from_forgery :except => [:destroy] # workaround for ActionController::InvalidAuthenticityToken
  
  # Action #edit to display the edit form
  def  edit
    @comment = Comment.find(params[:id])
  end
  
  # Action #update to update a Comment-record. 
  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash['success'] = Utils::FLASH_RECORD_UPDATED
      redirect_to @comment.request_referer
    else
      render :action => 'edit'
    end
  end
  
  # Action #destroy to delete a Comment-record. 
  def destroy
    cmt = Comment.find(params[:id])
    wiki = cmt.site
    cmt.destroy
    flash['success'] = Utils::FLASH_RECORD_DELETED
    redirect_to :controller => 'sites', :action => 'comments', :id => wiki.id
    #redirect_to request.referer TODO If you use this, functional tests will fail
  end
end
