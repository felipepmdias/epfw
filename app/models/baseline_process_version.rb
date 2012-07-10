class BaselineProcessVersion < Version
  
  belongs_to  :baseline_process, :foreign_key => 'baseline_process_id'

  validates_presence_of  :baseline_process

  # BaselineProcess version file will be created on save/checkin of version 1, which is the UserVersion
  # This is done to improve compare using XHTMLDiff. TinyMCE will make changes to HTML that we do not 
  # want to include in compare.  
  # TODO implement unit/integration/functional test
  def path(tinymce = false)
    p = File.join(self.wiki.path, "#{self.page.rel_path}_EPFWIKI_v#{self.version}.html")
    if File.exists? p or tinymce
      p
    else
      File.join(self.baseline_process.path, self.page.rel_path)
    end
  end
  
  def save_tinymce_html(h)
    File.open(self.path(true), 'w') {|f| f.write(h) }
  end
  
end