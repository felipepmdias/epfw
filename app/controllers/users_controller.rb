class UsersController < ApplicationController
  
  protect_from_forgery :except => :send_report
  
  layout 'management'
  
  before_filter :authenticate, :except => [:show]
  before_filter :authenticate_admin, :only => [:list, :admin]
  before_filter :authenticate_cadmin, :only => [:destroy, :cadmin, :adminmessage]
  
  protect_from_forgery :except => [:admin, :cadmin, :send_report]
    
  FLASH_REPORT_SENT = "Report sent!"
  FLASH_FAILED_TO_RESEND_PW = "New password could not be saved!"
  FLASH_NO_LONGER_CADMIN = "You are no longer the central administrator"  
  
  def index
    redirect_to :action => 'list'
  end
  
  def list
    @admins = User.find_all_by_admin('Y')
    @users = User.find_all_by_admin('N')
    @cadmin = User.find_central_admin
  end    
  
  def send_report
    Notifier.summary(params.merge(:user => session['user'])).deliver
    flash['success'] = FLASH_REPORT_SENT
    redirect_to :action => 'account', :id => session['user'].id
  end
  
  # TODO caching of this page
  def show
    @user = User.find(params[:id])
    @versions = UserVersion.find(:all, :order => 'created_on DESC', :conditions => ['user_id=?',@user.id])
    @comments = Comment.find(:all, :order => 'created_on DESC', :conditions => ['user_id=?',@user.id])
    @uploads = Upload.find(:all, :order => 'created_on DESC', :conditions => ['user_id=?',@user.id])
    @pages = WikiPage.find(:all, :order => 'created_on DESC', :conditions => ['tool=? and user_id=?','Wiki', @user.id])
    @tabitems = []
    @tabitems << {:text => "General", :id => 'general'} 
    @tabitems << {:text => "Comments (#{@comments.size.to_s})", :id => 'discussion'} 
    @tabitems << {:text => "Changes (#{@versions.size.to_s})", :id => 'changes'} 
    @tabitems << {:text => "Uploads (#{@uploads.size.to_s})", :id => 'uploads'}     
    @tabitems << {:text => "New Pages (#{@pages.size.to_s})", :id => 'new_pages'}   
  end

  def account
    select_user
  end
  
  def edit
    @user = User.find(params[:id])
    if request.get?
    else
      if  mine?(@user) || cadmin?
        if @user.update_attributes(params[:user].merge(:user => session['user']))
          flash.now['success'] = Utils::FLASH_RECORD_UPDATED
        end
      else
        flash.now['error'] = Utils::FLASH_NOT_OWNER        
      end
    end
  end
  
  def destroy
    #--
    # TODO Cannot destroy user with versions and comments, 
    # we should also do something with version and comments. Aassign versions 
    # and comments to admin user, and do a flash notice
    #++
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def cadmin
    @cadmin = User.find(session['user'].id) # about to become 'ordinary' admin
    @user = User.find(params[:id]) # about to become cadmin
    User.cadmin(@cadmin,@user)
    flash['notice'] = FLASH_NO_LONGER_CADMIN 
    redirect_to :action => 'list'
  end
  
  def admin
    @user = User.find(params[:id])
    @user.user = session['user'] # used for authorisation
    @user.admin = params[:admin]
    if  @user.save
      flash['success'] = Utils::FLASH_RECORD_UPDATED
    end
    redirect_to :action => 'list'
  end    
  
  def toggle_change_report_notification
    @user = User.find(params[:user_id])
    if  mine?(@user) || cadmin?
      @user.notify_daily = (@user.notify_daily - 1).abs  if params[:type] == 'D'
      @user.notify_weekly = (@user.notify_weekly - 1).abs  if params[:type] == 'W'
      @user.notify_monthly = (@user.notify_monthly - 1).abs  if params[:type] == 'M'
      @user.notify_immediate = (@user.notify_immediate - 1).abs  if params[:type] == 'I'
      #user.notify_dialy = 1
      @user.save!
    end
    render :inline => "<%= link_to_change_report_notification_toggle(params[:type], @user) %>"
  end
  
  # Action #notification creates or deletes (toggles) a notification of a certain type for a Page and Site
  def notification
    @user = User.find(params[:user_id])
    @site = Site.find(params[:site_id])
    @page = Page.find(params[:page_id])
    @type = params[:notification_type]
    if session['user'] == @user || cadmin?
      n = Notification.find(:first, :conditions => ["user_id=? and page_id=? and notification_type=?", @user.id, @page.id, @type])
      if  n
        n.destroy
      else
        n = Notification.create(:user => session['user'], :page => @page, :notification_type => @type)
      end
      respond_to do |format|
        format.js {  render :update do |page|
          page.replace_html params['div_id'], :inline => "<%= link_to_notification_toggle(@page, @type, @user)%>"
          page.visual_effect :highlight, params['div_id'], :duration => 2 
        end}
      end
    else
      #render :inline => "<%= link_to_notification_toggle(@page, @type, @user)%>"
    end
  end
  
  def admin_message # TODO changed this to admin_message. Rails 3
    @admin_message = AdminMessage.find(params[:id])
    if request.get?
    else
      if @admin_message.update_attributes(params[:admin_message])
        flash['success'] = Utils::FLASH_RECORD_UPDATED
      end
    end
  end
  
  protected
  def select_user #:doc:
    if params[:id]
      @user = User.find(params[:id])
    else
      @user = session['user']
    end
    if !cadmin? && !mine?(@user)
      @user = session['user']
      flash['notice'] = LoginController::FLASH_UNOT_ADMIN 
    end
  end
  
end
