require 'open-uri'

class OtherController < ApplicationController

  layout 'management'

  # Action #info displays information this application
  def about
    @version = Utils.db_script_version(ENV['EPFWIKI_ROOT_DIR'] + "db/migrate")
    sql = 'select max(version) from schema_migrations'
    #  TODO does not work in production
    #@database_schema = ActiveRecord::Base.connection.execute(sql).entries[0][0].to_i
    @database_schema = ActiveRecord::Base.connection.execute(sql).extend(Enumerable).to_a.first.first
    if  @database_schema.to_s == @version.to_s
      @version = nil
    else
      flash.now['warning'] = "Database seems out-of-date. Available scripts are of a higher version. Available is " + @version.to_s + ", installed is " + @database_schema.to_s 
    end
  end
    
  # Action #error is redirected to from ApplicationController.resque_action_in_public
  # to display a userfriendly error message
  def error
  end
  
  # See routes.rb
  def show404
      flash.now['error'] = 'The page you\'ve requested cannot be found.'
      render :action => 'error', :status => 404 
  end
 
end
