class Page < ActiveRecord::Base
    
  belongs_to :site #, :dependent => :destroy  

  before_create :extract_metadata_from_html
  
  validates_format_of :status, :with => /N.A|New|Updated|Undetermined|RemovedOrMoved|Harvested/ 
  validates_format_of :tool, :with => /EPFC|Wiki/   
  
  validates_presence_of   :rel_path, :site#, :presentation_name#, :uma_type, :filename
  #validates_length_of     :filename, :maximum => 250
  #validates_length_of     :uma_type, :maximum => 100
  #validates_length_of     :presentation_name, :maximum => 500
  validates_length_of     :rel_path, :maximum => 250
  
  validate :validate_rel_path_used, :on => :create
  
  # For creating a new page, use to specify the source version of the template or page
  # NOTE: depending where it is used (view or model) this stores an Id or and object.
  attr_accessor :source_version
  
  # For creating a new page, use to specify the user
  attr_accessor :user
  
  # When creating a new page, use to supply a note for creating the version
  attr_accessor :note
  
  # Used to remove HTML fragment that wikifies the HTML file so it can be edited. 
  PAGE_HEAD_SNIPPET_PATTERN = /<!-- epfwiki head.*head end -->/m
  # Used to replace treebrowser.js from HTML files because it chrashes the HTML editor 
  TREEBROWSER_PATTERN = /<script.*?scripts\/treebrowser\.js.*?<\/script>/i
  # Placeholder for TREEBROWSER_PATTERN , so we can easily place it back in the file
  TREEBROWSER_PLACEHOLDER = "<div id=\"treebrowser_tag_placeholder\"></div>"
  # Used to remove onload event from HTML files because it chrashed the HTML Editor
  BODY_TAG_PATTERN = /<body.*>/i
  # Used to add the page_script
  BODY_CLOSING_TAG_PATTERN = /<\/body>/i
  # Used to fix some layout problems with the 'horizontal rule'
  SHIM_TAG_PATTERN = /images\/shim.gif(")?( )*\/?>.?( )*?.?( )*?<\/td>/im 
  # Used to fix some layout problems with the 'horizontal rule'
  SHIM_TAG = "images/shim.gif\" /></td>"
  # Used to replace copyright notice from the file so it can be edited.
  COPYRIGHT_PATTERN = /<p>( )*?(.)?( )*?copyright(.)*?<\/p>/im 
  # Placeholder for copyright notice we find with COPYRIGHT_PATTERN
  COPYRIGHT_PLACEHOLDER = "<!-- copyright statement -->"
  TITLE_PATTERN = /<title>(.)*<\/title>/i
  HEAD_PATTERN = /<head>(.)*<\/head>/im
  TITLE2_PATTERN = /class="pageTitle">(.)*<\/td>/ # TODO use regular expressions the right way
  TITLE2_START = /class="pageTitle">/i 
  TITLE2_END = /<\/td>/ 
  ELEMENT_TYPE_PATTERN = /<meta(.)*element_type(.)*>/i
  
  def self.get_snippets
      return [IO.readlines(File.expand_path('app/models/page_head_snippet.txt', Rails.root)).join]
  end
  
  # Method #enhance_file enhances a file if it hasn't been enhanced yet 
  # with e.g. Javascript libs, CSS, (script) elements
  def self.enhance_file(path, snippets = Page.get_snippets)
    h = IO.readlines(path).join 
    if h.index('epfwiki head start')
      logger.info("File skipped (already enhanced): #{path}")
    else
      new_html = h.gsub(/<\/head>/i, snippets[0] + "\n</head>")
      new_html = new_html.gsub("width=\"100%\"", "width=\"99%\"")  # workaround to prevent scrollbar from being displayed
      file = File.new(path, "w")
      file.puts(new_html)
      file.close
    end
  end
  
  def path
    return self.site.path + '/' + self.rel_path 
  end
  
  def html
    IO.readlines(self.path).join
  end

  def url(absolute = false, request_host = nil)
    self.site.url(absolute, request_host).gsub('/index.htm','/') + self.rel_path
  end

  # extracts and returns the UMA Presentation Name from HTML
  def self.uma_presentation_name_from_html(html)
    return uma_value_from_html(html, /<meta.*? name="uma\.presentationName".*?>/)
  end

  # UMA Name from HTML
  def self.uma_name_from_html(html)
    return uma_value_from_html(html, /<meta.*? name="uma\.name".*?>/)
  end

  # UMA Type from HTML
  def self.uma_type_from_html(html)
    return uma_value_from_html(html, /<meta.*? name="uma\.type".*?>/)
  end

  # Order of content and name does not seem to be always the same? 
  # So this method is independent of order 
  def self.uma_value_from_html(html, pattern)
    match = pattern.match(html)
    result = ''
    if match
      match2 = /content="(.*?)"/.match(match[0])
      result = match2[1] if match2
    end
    return result
  end
  
  def overview_table
    match = /class="overviewTable".*?>(.*?)<\/table>/m.match(self.html)
    if match # some pages may not have overviewTable section
      match1 = /td.*?>(.*?)<\/td>/m.match(match[1]) # returns only the text from the overviewTable section
      if match1
        result = match1[1]
      end
    else
      result = ""
    end
    
    return result
  end
  
  def validate_rel_path_used
    if self.tool == 'Wiki'
      errors.add(:rel_path, "already used; can\'t create another page with relative path #{self.rel_path}") if Page.exists?(['rel_path = ? and site_id = ?',self.rel_path, self.site.id])
    end
  end
  
  def extract_metadata_from_html
    h = self.html
    self.uma_type = Page.uma_type_from_html(h)
    self.uma_name = Page.uma_name_from_html(h)
    logger.debug("...#{Page.uma_presentation_name_from_html(h)}")
    self.presentation_name = Page.uma_presentation_name_from_html(h)
    self.filename = File.basename(self.path)
    self.body_tag = BODY_TAG_PATTERN.match(h).to_s
    self.treebrowser_tag = TREEBROWSER_PATTERN.match(h).to_s
    self.copyright_tag = COPYRIGHT_PATTERN.match(h).to_s
    self.head_tag = Page::HEAD_PATTERN.match(h).to_s
  end

end
