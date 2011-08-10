class Upload < ActiveRecord::Base

  belongs_to :user
  belongs_to :reviewer,              :class_name => 'User',    :foreign_key => 'reviewer_id'

  attr_accessor :file
  validates_presence_of :user
  #after_save :process

  def new_filename
    return  "#{self.id.to_s}.#{self.filename.split('.').last.downcase}"
  end
  
  def path
    return "#{ENV['EPFWIKI_ROOT_DIR']}public/uploads/#{self.new_filename}"
  end
  
  def file=(file)
    @file = file
    write_attribute 'filename', file.original_filename 
    write_attribute 'content_type', file.content_type.strip 
  end
  
  def save_file
    raise 'Cannot save without id' if self.id.nil?
    uploads_path = "#{ENV['EPFWIKI_ROOT_DIR']}public/uploads/"
    FileUtils.makedirs(uploads_path) if !File.exists?(uploads_path)
    self.rel_path = write_attribute 'rel_path', "uploads/#{self.id.to_s}.#{self.filename.split('.').last.downcase}"
    File.open(self.path, 'wb') do |file_date|
      file_date.puts file.read
    end
  end
  
  def url(absolute = false, request_host = ENV['EPFWIKI_HOST'])
    s = "/uploads/#{self.new_filename}"
    s = "http://#{request_host}#{s}" if absolute
    s
  end
  
end
