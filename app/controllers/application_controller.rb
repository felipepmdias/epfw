# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.


class ApplicationController < ActionController::Base

  protect_from_forgery

  #########
  protected   
  #########


  def user?
    if session and session['user']
      true
    else
      false
    end
  end

  def admin?
    if user? and session['user'].admin?
      true
    else
      false
    end
  end

  def cadmin?
    if user? and session['user'].cadmin?
      true
    else
      false
    end
  end

  def mine?(obj)
    if obj.class.name == User.name
      obj.id == session['user'].id
    else
      obj.user_id == session['user'].id
    end
  end
  
  def log_error(exception) #:doc:
    super(exception)
    begin
      # ENHANCEMENT don't send error email when action error causes an error 
      Notifier.deliver_error_report(exception, clean_backtrace(exception), 
      session.instance_variable_get("@data"), 
      params, 
      request.env)
    rescue => e
      logger.error(e)
    end
  end
  
  # all exceptions are redirected to OtherController.error
  def rescue_action_in_public(exception) #:doc:
    flash['error'] = exception.message
    flash['notice'] = "An application error occurred while processing your request. This error was logged and an email was sent to notify the administrator."
    flash['notice'] = 'We\'re sorry, but something went wrong. We\'ve been notified about this issue and we\'ll take a look at it shortly.'
    redirect_to :controller => 'other', :action => 'error'
  end
  
  # instead of an error stack we want to display a nice user friendly error message
  def local_request? #:doc:
    false
  end
  
  # The #authenticate method is used as a <tt>before_hook</tt> in
  # controllers that require the user to be authenticated. If the
  # session does not contain a valid user, the method
  # redirects to the LoginController.login.
  #-- 
  # ENHANCEMENT to have caching of pages per user group add something like :params => params.merge( :utype=> 'admin' ) 
  #++
  def authenticate #:doc:
    unless session['user']
      logger.debug('No session, redirecting to login')
      session['return_to'] = request.fullpath
      redirect_to :controller => 'login' 
      return false
    end
  end
  
  def authenticate_admin #:doc:
    logger.debug("Authenticate admin #{session['user']}")
    if !admin?
      logger.debug("User not authenticated as admin")
      flash['notice'] = 'Administrators privileges are required to access this function'
      flash['error'] = LoginController::FLASH_UNOT_ADMIN # TODO should be flash.now?
      Notifier.authorisation_problem(session['user'], session.instance_variable_get("@data"), params, request.env).deliver
      redirect_to :controller => 'other', :action => 'error'
      return false        
    end
  end
  
  def authenticate_cadmin #:doc:
    unless session and session['user'] and session['user'].cadmin?
      flash['notice'] = 'You need to be the central administrator to access this function'
      flash['error'] = LoginController::FLASH_UNOT_CADMIN
      Notifier.authorisation_problem(session['user'], session.instance_variable_get("@data"), params, request.env).deliver
      redirect_to :controller => 'other', :action => 'error'
      return false
    end
  end
  
  def create_cookie(theUser)
    cookies[:epfwiki_id] = {:value => theUser.id.to_s, :expires => Time.now+31536000}
    cookies[:epfwiki_token] = {:value => Utils.hash_pw(theUser.hashed_password),:expires => Time.now+31536000}
  end
  
  def expire_cookie
    cookies.delete :epfwiki_id
    cookies.delete :epfwiki_token
  end

end
