class Sweeper < ActionController::Caching::Sweeper
  
  observe WikiPage, Checkout, Comment, Wiki, UserVersion, Upload 
  
  # TODO more advanced expiration
  def after_create(record)
    if record.is_a?(Wiki) || record.is_a?(Checkout) || record.is_a?(Comment) || record.is_a?(UserVersion) || record.is_a?(Wiki) || record.is_a?(Upload)
      expire_all_pages
    elsif record.is_a?(WikiPage)
      expire_all_pages if record.tool = 'Wiki'
    end
  end
  
  def after_destroy(record)
    if record.is_a?(Checkout)
      expire_all_pages
    end
  end
  
end