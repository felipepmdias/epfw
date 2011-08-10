class BaselineProcessVersion < Version
  
  belongs_to  :baseline_process, :foreign_key => 'baseline_process_id'

  validates_presence_of  :baseline_process
  
  def path
    return self.baseline_process.path + '/' + self.page.rel_path
  end
  
end