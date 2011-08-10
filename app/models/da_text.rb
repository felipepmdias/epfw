# Text is a reserved word, so we use DaText
class DaText < ActiveRecord::Base
  
    belongs_to :reviewer, :class_name => "User", :foreign_key => "reviewer_id"  

    # CommentsController and FeedbacksController don't have own list actions, so we use this attribute
    # to redirect back to whereever we came from. 
    attr_accessor :request_referer
    #-- 
    # TODO problably there is a better way to do this
    #++    
  
end




