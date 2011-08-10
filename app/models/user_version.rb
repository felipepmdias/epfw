class UserVersion < Version

  def path
    return self.wiki.path + '/' + self.rel_path
  end
    
  def html=(h)
    logger.debug("Saving HTML to #{self.path}")
    f = File.new(self.path, "w")
    f.puts(h)
    f.close
    # works on the file, we are using tidy lib
    self.tidy if self.user_version? 
    h = self.html.gsub(Page::SHIM_TAG_PATTERN, Page::SHIM_TAG)
    f = File.new(self.path, "w")
    f.puts(h)
    f.close
end
  
end