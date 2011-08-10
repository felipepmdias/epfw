class Notifier < ActionMailer::Base

  default :from => ENV['EPFWIKI_REPLY_ADDRESS']
  
  def welcome_pw_confirmationlink(user, request_host = ENV['EPFWIKI_HOST'])
    content_type "text/html"
    @recipients = user.email
    @from = ENV['EPFWIKI_REPLY_ADDRESS']
    @subject =  "[" + ENV['EPFWIKI_APP_NAME'] + "] Welcome" 
    @user = user
    @cadmin = User.find_central_admin
    @subject = @subject
    @request_host = request_host
  end
  
  
  def lost_password(user, urls)
    content_type "text/html"
    @recipients = user.email
    @from = ENV['EPFWIKI_REPLY_ADDRESS']
    @subject = "[" + ENV['EPFWIKI_APP_NAME'] + "] New Password"
    @user = user
    @admin = User.find_central_admin
    @cnt = User.count
    @urls = urls
  end

  def error_report(exception, trace, session, params, env, sent_on = Time.now)
    content_type "text/html" 
    @recipients         = User.find_central_admin.email
    @from               = ENV['EPFWIKI_REPLY_ADDRESS']
    @subject            = "[Error] exception in #{env['REQUEST_URI']}" 
    @sent_on            = sent_on
    @exception  = exception
    @trace      = trace
    @session    = session
    @params     = params
    @env        = env
  end
  
  def summary(params, runtime = Time.now)
    content_type "text/html" 
    
    case params[:type]
    when 'D' # daily
      starttime = (runtime - 1.day).at_beginning_of_day
      endtime = runtime.at_beginning_of_day
      @bcc = Utils.email_addresses_4_report(User.find_all_by_notify_daily(1))
      subject_text = 'Daily'
    when 'W' # weekly
      starttime = (runtime - 1.week).at_beginning_of_week
      endtime = runtime.at_beginning_of_week
      @bcc = Utils.email_addresses_4_report(User.find_all_by_notify_weekly(1))
      subject_text = 'Weekly'
    when 'M' # monthly
      starttime = (runtime - 1.month).at_beginning_of_month
      endtime = runtime.at_beginning_of_month
      @bcc = Utils.email_addresses_4_report(User.find_all_by_notify_monthly(1))
      subject_text = 'Monthly'
    else
      raise 'Report type is required'
    end
    
    @bcc = Utils.email_addresses_4_report(params[:user]) unless params[:user].blank?
    @subject = "[#{ENV['EPFWIKI_APP_NAME']}] #{subject_text} Summary" 

    items = UserVersion.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ]) +
    Comment.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ]) +
    Upload.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ]) +
    Wiki.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ])+
    Update.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ]) +
    User.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ]) +
    WikiPage.find(:all, :conditions => ['created_on > ? and created_on < ? and tool=?', starttime, endtime, 'Wiki'])
    Checkout.find(:all)
    items.sort_by {|item|item.created_on}
    @wikis = []
    items.each do |item|
      logger.debug("item: #{item.inspect}")
      w = nil
      case item.class.name
      when Comment.name then w = item.site
      when Wiki.name then w = item
      when Update.name then w = item.wiki
      when Checkout.name then w = item.site
      when Version.name then w = item.wiki
      end
      @wikis << w if !w.nil?
    end
    @wikis = @wikis.uniq    
    @from               = ENV['EPFWIKI_REPLY_ADDRESS']
    @sent_on            = Time.now
    @runtime    = runtime
    @endtime    = endtime
    @starttime  = starttime
    @contributions   = items
    @subject    = subject
    @cadmin      = User.find_central_admin
    @host       = ENV['EPFWIKI_HOST']
    @items = items
  end 
  
  def env_to(user, session, params, env, sent_on = Time.now)
    content_type "text/html" 
    @recipients         = user.email
    @from               = ENV['EPFWIKI_REPLY_ADDRESS']
    @subject            = "[" + ENV['EPFWIKI_APP_NAME'] + "] " + params[:action]
    @sent_on            = sent_on
    @session    = session
    @params     = params
    @env        = env
  end
  
  def site_status(update, s)
    content_type "text/html" 
    #@from = ENV['EPFWIKI_REPLY_ADDRESS']
    @cadmin = User.find_central_admin
    @update = update
    @s = s
    #@subject =  "[#{ENV['EPFWIKI_APP_NAME']}] #{s}"
    #@recipients = update.user.email
    #@cc = @cadmin.email
    mail(:cc => @cadmin.email, :to => update.user.email, :subject =>  "[#{ENV['EPFWIKI_APP_NAME']}] #{s}"
)
  end
  
  def notification(theUsers, subject, introduction, text, request_host = ENV['EPFWIKI_HOST'])
    #recipients   # hide recipients
    #bcc               subject       
    #from          ENV['EPFWIKI_REPLY_ADDRESS']
    content_type  "text/html" 
    #body          text
    @link = "<a href=\"http://#{request_host}/users/account\">#{ENV['EPFWIKI_APP_NAME']}</a>"
    @introduction = introduction
    #@body = text
    @text = text
    @cadmin = User.find_central_admin
    mail(:bcc => Utils.email_addresses_4_report(theUsers), :subject => "[#{ENV['EPFWIKI_APP_NAME']}] #{subject}") do |format|
      format.html
      #format.text
    end
  end
  
  # TODO replace with notification
  def email(theUsers, theSubject, theFilePaths, theText, cc = nil)
    @from = ENV['EPFWIKI_REPLY_ADDRESS']
    @cc = Utils.email_addresses_4_report(cc) unless cc.nil?
    content_type "text/html" 
    @subject = "[" + ENV['EPFWIKI_APP_NAME'] + "] " + theSubject
    @recipients = Utils.email_addresses_4_report(theUsers)
    @text = theText
    @admin = User.find_central_admin
    for filePath  in theFilePaths
      attachment :content_type => "application/zip",   :body => File.open(filePath, "rb") {|io| io.read}, :filename => filePath.split("/").last
    end
  end
  
  def contributions_processed(user, contributions)
    @recipients = Utils.email_addresses_4_report(user)
    content_type "text/html" 
    @contributions = contributions
    @cadmin = User.find_central_admin
    @user = user
    @from = ENV['EPFWIKI_REPLY_ADDRESS']
    @bcc = Utils.email_addresses_4_report(@cadmin)
    @subject = "[#{ENV['EPFWIKI_APP_NAME']}] Your contribution has been processed"    
  end
  
  def authorisation_problem(user, session, params, env)
    user = User.new(:name => 'Unknown', :email => 'Unknown') if user.nil?
    content_type 'text/html' 
    @cadmin     = User.find_central_admin 
    @recipients         = Utils.email_addresses_4_report(@cadmin)
    @from               = ENV['EPFWIKI_REPLY_ADDRESS']
    @subject            = "[#{ENV['EPFWIKI_APP_NAME']}] Autorisation Problem Detected"
    @session    = session
    @params     = params
    @env        = env
    @subject    = @subject
    @user       = user
  end
  
  def feedback(feedback) # TODO implement test
    content_type 'text/html' 
    @cadmin     = User.find_central_admin 
    @recipients         = Utils.email_addresses_4_report(@cadmin)
    @from               = ENV['EPFWIKI_REPLY_ADDRESS']
    @subject            = "[#{ENV['EPFWIKI_APP_NAME']}] Feedback Posted"
    @subject    = @subject
    @feedback   = feedback
    @anywiki    = Wiki.find(:first, :conditions => ['obsolete_on is null'])
  end

end
