class RssController < ApplicationController

  #session :off # stateless RSS requests # TODO DEPRECATED, if session is not accessed it is not created
  
  caches_page :list
  
  def list
    @cadmin = User.find_central_admin
    @updates = Update.find(:all, :order => 'finished_on DESC', :conditions => ['finished_on > ?', Time.now - 14.days], :limit => 14)
    @uploads = Upload.find(:all, :order => 'created_on DESC', :conditions => ['created_on > ?', Time.now - 14.days], :limit => 14)
    unless params[:site_folder] == 'all' then
      @wiki = Wiki.find_by_folder(params[:site_folder])
      @versions = Version.find(:all, :order => 'created_on DESC', :conditions => ['wiki_id=? and baseline_process_id is null and created_on > ? and not exists (select * from checkouts c where c.version_id=versions.id)', @wiki.id, Time.now - 14.days ], :limit => 14)
      @comments = Comment.find(:all, :order => 'created_on DESC', :conditions => ['site_id=? and created_on > ?', @wiki.id, Time.now - 14.days], :limit => 14)
    else
      @versions = Version.find(:all, :order => 'created_on DESC', :conditions => ['baseline_process_id is null and created_on > ? and not exists (select * from checkouts c where c.version_id=versions.id)',Time.now - 14.days], :limit => 14)
      @comments = Comment.find(:all, :order => 'created_on DESC', :conditions => ['created_on > ?',Time.now - 14.days], :limit => 14)
    end if
    headers['Content-Type'] = 'application/rss+xml'
    render :layout => false
  end
  
  # author: RB
  def practice_feed # processes the request for a practice feed
    @wiki = Wiki.find_by_folder(params[:site_folder]) # gets the wiki site folder that is part of the requesting url
    if (@wiki == nil) 
        render :action => 'error', :status => 404         
    else
      @practice_name = params[:practice_name] # gets the practice name that is part of the requestin url
      @wikiId = Wiki.find(@wiki.id) # finds the wiki site with the given id
      # queries for the practice page in this particular wiki site
      @practice = WikiPage.find(:first, :conditions => ['uma_name=? and site_id=?', @practice_name, @wiki.id])
      
      if (@practice == nil)
        render :action => 'error', :status => 404
      end  
    end
  end

  # author: RB
  def any_uma_type_feed # processes the request for any uma element feed
    @wiki = Wiki.find_by_folder(params[:site_folder]) # gets the wiki site folder that is part of the requesting url
    @umaType = params[:uma_type] # gets the uma type that is part of the requesting url
    if (@wiki == nil) 
        render :action => 'error', :status => 404         
    else
      @wikiId = Wiki.find(@wiki.id) # finds the wiki site with the given id
      # queries for all the elements of given uma type in this particular wiki site
      @umaElements = WikiPage.find(:all, :conditions => ['uma_type=? and site_id=?', @umaType, @wiki.id])
    
      if (@umaElements.size == 0)
        render :action => 'error', :status => 404
      end  
    end
  end
   
end

