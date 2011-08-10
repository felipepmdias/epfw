class UploadsController < ApplicationController
  
  layout 'management'
  
  before_filter :authenticate, :except => [:list, :show]
  before_filter :authenticate_admin, :only => [:review, :review_note]
  before_filter :authenticate_cadmin, :only => [:destroy]
  
  cache_sweeper :sweeper, :only => [:new]
    
  protect_from_forgery :except => [:destroy] 
  
  def index
    list
    render :action => 'list'
  end
  
  def list
    @uploads = Upload.order("created_on DESC").paginate(:per_page => Rails.application.config.per_page, 
    :page => params[:page])
  end
  
  def show
    @upload = Upload.find(params[:id])
  end
  
  def create
    @upload = Upload.new(params[:upload].merge(:user => session['user']))
    if @upload.save
      @upload.save_file
      flash['success'] = 'Upload was successfully created.'
      users = User.find(:all, :conditions => ['notify_immediate=?', 1])
      unless users.empty?
        subject = "New upload from #{@upload.user.name}"
        introduction = "<p>User #{@upload.user.name} uploaded a document or image <a href=\"#{@upload.url(true, request.host + (request.port == 80 ? '' : ':' + request.port.to_s))}\">#{@upload.filename}</a></p>"
        Notifier.notification(users,subject,introduction, @upload.description, request.host + (request.port == 80 ? '' : ':' + request.port.to_s)).deliver
      end        
      redirect_to :action => 'index'
      #render :action => 'new'
    end # TODO flash fail
  end
  
  def new
    @upload = Upload.new
  end
  
  def edit
    @upload = Upload.find(params[:id])
  end
  
  def update
    @upload = Upload.find(params[:id])
    logger.debug("mine?:#{mine?(@upload)}, admin?: #{admin?}")
    if mine?(@upload) || admin?
      if @upload.update_attributes(params[:upload])
        flash['success'] = 'Upload was successfully updated.'
        redirect_to :action => 'index'
      else
        render :action => 'edit'
      end
    else
      flash['error'] = Utils::FLASH_NOT_OWNER
      render :action => 'edit'
    end
  end
  
  def destroy
    @upload = Upload.find(params[:id])
    @upload.destroy
    redirect_to request.referer
  end
  
end
