EPFWikiRails3::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  ENV['EPFWIKI_APP_NAME'] = 'EPF Wiki'
  ENV['EPFWIKI_PUBLIC_FOLDER'] = 'public'
  ENV['EPFWIKI_EDITOR'] = 'tinymce' # TODO Bug 218832 - RTE
  ENV['EPFWIKI_ROOT_DIR'] = File.expand_path(Rails.root) + '/'
  ENV['EPFWIKI_HOST'] = "localhost" # used for jobs, when there is no host variable in the environment
  ENV['EPFWIKI_SITES_FOLDER'] = 'bp'
  ENV['EPFWIKI_SITES_PATH'] = ENV['EPFWIKI_ROOT_DIR'] + ENV['EPFWIKI_PUBLIC_FOLDER'] + '/' + ENV['EPFWIKI_SITES_FOLDER']
  ENV['EPFWIKI_WIKIS_FOLDER'] = 'wikis' 
  ENV['EPFWIKI_WIKIS_PATH'] = ENV['EPFWIKI_ROOT_DIR'] + ENV['EPFWIKI_PUBLIC_FOLDER'] + '/' + ENV['EPFWIKI_WIKIS_FOLDER']
  ENV['EPFWIKI_DIFFS_PATH'] = ENV['EPFWIKI_ROOT_DIR'] + ENV['EPFWIKI_PUBLIC_FOLDER'] + "/#{Rails.env}_diffs/"
  #ENV['EPFWIKI_DOMAINS'] = "@epfwiki.org @openup.org" # specify to restrict valid emails to these domains. Uncomment to allow all.
  
  ENV['EPFWIKI_REPLY_ADDRESS'] = "no-reply@epf.eclipse.org"
  ENV['EPFWIKI_TEMPLATES_DIR'] = "#{ENV['EPFWIKI_ROOT_DIR']}#{ENV['EPFWIKI_PUBLIC_FOLDER']}/templates/"
  
  ENV['EPFWIKI_GOOGLE_CUSTOM_SEARCH'] = 'N' # Google Custom Search example for EPFWiki.net
  
   # authentication methods that can be used to authenticate users
  ENV['EPFWIKI_AUTH_METHODS'] = 'validemail' # valid values, for instance: bugzilla,basic,validemail
  #ENV['EPFWIKI_AUTH_BASIC'] = 'home.global.logicacmg.com,401,logicacmg.com'  # host,fail code,domain for creating email
  #ENV['EPFWIKI_AUTH_BUGZILLA'] = 'bugs.eclipse.org,443'  # host,port
  config.per_page = 25
  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true # TODO revert this to false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end
