# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

  # TODO rails 3 copy van mine? in application controller
  def mine?(obj)
    if obj.class.name == User.name
      obj.id == session['user'].id
    else
      obj.user_id == session['user'].id
    end
  end

  # TODO rails 3 copy van mine? in application controller
  def user?
    logger.debug("session: #{session.inspect}")
    if session and session['user']
      logger.debug("session['user']: #{session['user'].inspect}")
      true
    else
      false
    end
  end

  # TODO rails 3 copy van mine? in application controller
  def admin?
    if user? and session['user'].admin?
      true
    else
      false
    end
  end

  # TODO rails 3 copy van mine? in application controller
  def cadmin? # TODO Rails 3 
    if user? and session['user'].cadmin?
      true
    else
      false
    end
  end

  # Helper to simplify In-Place Editing 
  # http://madrobby.github.com/scriptaculous/ajax-inplaceeditor/
  def editable_content(options)
    options[:content] = { :element => 'span' }.merge(options[:content])
    options[:url] = {}.merge(options[:url])
    options[:ajax] = { :okText => 'Save', :cancelText => 'Cancel'}.merge(options[:ajax] || {})
    script = Array.new
    script << 'new Ajax.InPlaceEditor('
    script << "  '#{options[:content][:options][:id]}',"
    script << "  '#{url_for(options[:url])}',"
    script << "  {"
    script << options[:ajax].map{ |key, value| "#{key.to_s}: #{value}" }.join(", ")
    script << "  }"
    script << ")"
    content_tag(
                options[:content][:element],
                options[:content][:text],
                options[:content][:options]
    ) + javascript_tag( script.join)
  end
  
  def link_to_review_note(comment)
    if admin?
      editable_content(:content => {:element => 'span', :text => comment.review_note,
            :options => {:id => "review_note_#{comment.id}",:class => 'editable-content'}},
            :url => { :controller => 'review', :action => 'note',:id => comment.id},
            :ajax => {:okText => "'Ok'",:cancelText => "'Cancel'" })
    else
      comment.review_note
    end
  end
  
  # TODO a better name for this method
  def menulink_to(*args)
    logger.debug("Creating menulink #{args.inspect}, #{params[:action]}")
    current = @current || params[:action].capitalize 
    s=' class="current"' if args[0].downcase == current.downcase
    if current == 'Edit' 
      txt = "Are you sure? By navigating away from the editor any unsaved changes will be lost."
      if args.size == 3
        args.last[:confirm] = txt
      else
        args << {:confirm => txt}        
      end
    end
    args[0] = raw "<span>#{args[0]}</span>"
    raw "<li#{s}>" + link_to(*args) + '</li>'
  end
  
  # Replacement error_messages_for, this was deprecated in Rails 3
  def error_messages_for(obj)
    if obj.errors.any?
      raw("<div class=\"errorExplanation\" id=\"errorExplanation\">\n"+
      "<h2>#{obj.errors.size} errors prohibited this #{obj.class.name.downcase} from being saved</h2>" +
      "<ul><li>" + obj.errors.full_messages.join("</li>\n<li>") + 
      "</li>\n</ul></div>")
    else
      ""	
    end
  end
  
  # Helper #tinymce in your view to render textarea's as TinyMCE textarea's
  def tinymce(theme = 'simple')
    @tinymce = theme
  end

   # Link To for a Page 
  def link_to_page(page)
      link_to(raw(page.presentation_name + ' ' + image_tag("link.gif",:border => 0,:title => "Activate page \"#{page.presentation_name}\" in site \"#{page.site.title}\"")), page.url)
  end
    
  # Helper #link_to_notification_toggle
  def link_to_notification_toggle(page, notification_type, user = session['user'])
    html = []
      notification = Notification.find(:first, :conditions => ["user_id=? and page_id=? and notification_type=?", user.id, page.id, notification_type])
      if session['user'] && (mine?(user) || cadmin?)
        div_id = "notification_" + page.id.to_s + "_" + notification_type
        html << raw("<span id=\"" + div_id + "\">")
        txt = raw "<input type=checkbox>notify me of new comments and changes"
        txt = raw "<input type=checkbox checked>notify me of new comments and changes" if notification
        html << link_to(txt, 
          url_for(:div_id => div_id, :controller => "users", :action => "notification", 
            :page_id => page.id, :site_id => page.site.id,:user_id => user.id, 
            :notification_type=> notification_type), :remote => true) # TODO Rails 3 was link_to_remote
        html << raw("</span>")
      else
        html << raw("<input type=checkbox #{'checked' if notification} DISABLED>notify me of new comments and changes")
      end
    raw html.join("\n")
  end
              
  def link_to_done_toggle(record)
    class_name = 'DaText'
    class_name = record.class.name if ['Version','Upload', 'UserVersion', 'BaselineProcessVersion', 'Comment', 'Feedback'].include?(record.class.name)
    html = []
    html << "<span id=\"" + div_id(record, "done_toggle") + "\">"
    if record.done == 'Y'
      title = 'Click to mark this record \'todo\''
      html4checkbox = raw "<input type=checkbox checked>"
    else
      title = 'Check to mark this record \'done\''
      html4checkbox = raw "<input type=checkbox>"
    end        
    if  !session["user"] || !admin?
      html << html4checkbox.gsub('type=checkbox', 'type=checkbox disabled=disabled')
    else
      html << link_to(html4checkbox, url_for(:controller => 'review', 
        :action => "toggle_done", :id => record.id, :class_name => class_name), 
        :remote => true) # TODO rails 3 was link_to_remote
    end
    html << "</span>"
    raw html.join("\n")
  end
                
    # Helper #link_to_reviewer to set the reviewer. See ReviewController.
    def link_to_reviewer(record)
      url = []
      url << "<span id=\"" + div_id(record, "reviewer") + "\">"
      if  !session["user"]
        if  record.reviewer_id != nil
          url << link_to_user(record.reviewer)
        end
      else 
        if  record.reviewer_id == nil
          if  admin?
            url << link_to("_______", url_for(:controller => 'review', :action => 'assign', :id => record.id, :class_name => record.class, :div_id => div_id(record, "reviewer")), :remote => true ) # TODO rails3 was link_to_remote
          else
            url << "" 
          end
        else
            url << link_to(record.reviewer.name, url_for(:controller => 'review', :action => 'assign', :id => record.id, :class_name => record.class, :div_id => div_id(record, "reviewer")), :remote => true ) # TODO rails3 was link_to_remote
        end
        url << "</span> "
      end
      raw url.join("\n")
    end
                    
  # link_to helper method for a Version. Renders a link with a given prefix (often "version") with possibly a lot of clickable images displaying status
  def link_to_version(version,urlprefix)
    link = [] 
     # TODO below incorrect
      urlprefix = 'CHECKOUT' if version.version.nil?
      link << link_to(urlprefix + " " + version.version.to_s,:controller => 'versions',:action => 'show',:id => version.id)
      if  !version.version_id
      else
        source_version = version.source_version
        if  version.wiki_id != source_version.wiki_id 
          from_site = source_version.wiki
          to_site = version.wiki
          link << link_to(image_tag('site.gif', :border => 0,  :title => 'Based on version ' + source_version.version.to_s + " from site " + from_site.title) ,:controller => 'versions',:action => 'show',:id => source_version.id)
        else
          if version.page_id != source_version.page_id
            base_page = source_version.page
            link << link_to(image_tag('new.png', :border => 0, :title => 'New page based on  ' + source_version.page.presentation_name + " version " + source_version.version.to_s) ,:controller => 'versions',:action => 'show',:id => source_version.id)  
          else
            if  version.version != source_version.version + 1
              link <<  " (based on "
              link << link_to(" version " + source_version.version.to_s,:controller => 'versions',:action => 'show',:id => source_version.id)
              link <<  ")"
            end
          end
        end
      end
      if version.current
        link << image_tag('harvest.gif', :title => 'This version is the current version')
      end
      checkout = version.checkout
      if  checkout
        user = checkout.user
        link << link_to(image_tag('checkout.gif', :border => 0, :title =>'Version is checked-out by ' + user.name ),:controller => 'versions',:action => 'show',:id => version.id)
        link << " " 
        if user == session['user'] || cadmin?
          link << link_to(image_tag('edit.gif', :border => 0, :title =>'Version is checked-out by you. Click to continue editing.' ),:controller => 'pages',:action => 'edit',:checkout_id => checkout.id)
        end
      end
      link << link_to(image_tag('compare.gif', :border => 0, :title =>'Compare with previous version' ),:controller => 'versions', :action => 'diff',:id => version.id) # TODO hier stond version niet version.id 
      link << link_to(image_tag('txt.gif', :border => 0,  :title =>'View as plain text' ), {:controller => 'versions',:action => 'text',:id => version.id}) # TODO 
    raw link.join("\n")
  end
                      
  # Helper for a Version 
  def link_to_version2(version)
    link_to_page(version.page) + ' ' + link_to_version(version,'version')
  end
                        
  # Helper for a Site
  def link_to_site(site)
    img = "link.gif"
    img = "link_gs.gif" if !site.wiki?
    ttl = site.title
    ttl = site.title + ' (OBSOLETE)' unless site.obsolete_on.nil?
    link = link_to(site.title,:controller => 'sites',:action => 'description',:id => site.id) #if !admin?
    link += raw(' ' + link_to(image_tag(img,:border => 0,:title => "Activate site \"#{site.title}\""), site.url, 
      :title => "Activate site \"#{site.title}\"", 'data-popup' => 'true'))
    if  site.type == 'BaselineProcess'
     link += raw(' ' + link_to(image_tag("csv.gif", :border => 0, :title => "Download content information as CSV"), 
        {:controller => "sites", :action => "csv", :id => site.id}, :method => :post ))
    end 
    link
  end
                          
  # link_to helper method for a User
  def link_to_user(user)
    link_to(user.name,:controller => 'users',:action => 'show',:id => user.id) + image_tag("user" + user.admin + '.png', :border => 0, :title => "") 
  end
                            
  # link_to helper method for a Comment
  def link_to_comment(comment)
    link_to(truncate(strip_tags(comment.text)), :controller => 'pages', :action => 'discussion', :site_folder => comment.site.folder, :id => comment.page.id)
  end
     
  # TODO vervangen door div_for                         
  # returns unique div id from a record in a page
  def div_id(record, call_id)
    return  record.class.to_s + record.id.to_s + "_" + call_id
  end
                                  
end
                                
