class Comment < DaText

    belongs_to :site 
    belongs_to :user 
    belongs_to :page
    belongs_to :version 

    after_create :create_notification
    before_create :cannot_comment_if_co # validate on before_create?
    validate :check_versions, :on => :create #before_validation_on_create 
    
    validates_presence_of :text, :user, :page, :site, :version

    # Set some redundant properties
    #--
    # TODO remove these redundant properties
    #++
    def check_versions
      if self.version.nil?
        if self.page.current_version
          self.version = self.page.current_version 
        end
      end
      unless self.version.nil?
        self.page = self.version.page 
     end
     self.site = self.page.site
    end

    def cannot_comment_if_co
      if self.version.nil?
        errors.add("Cannot comment on new pages that are in the process of being created (not checked in yet). Comments would be left dangling on undo checkout.")       
      end
    end
    
    def create_notification
      Notification.find_or_create(self.page, self.user, Page.name)
    end

end