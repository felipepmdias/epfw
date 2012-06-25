class Version < ActiveRecord::Base
  
  belongs_to  :user
  belongs_to  :wiki, :foreign_key => 'wiki_id' # TODO not necessary?
  belongs_to  :page
  has_one     :checkout
  belongs_to  :source_version,        :class_name => 'Version', :foreign_key => 'version_id'
  belongs_to  :reviewer,              :class_name => 'User',    :foreign_key => 'reviewer_id'
  has_many    :child_versions,        :class_name => 'Version', :foreign_key => 'version_id'
  has_many    :comments
  
  before_destroy :delete_file

  attr_accessor :type_filter # used for selection filter

  # NOTE: it is not possible to use 'update' below, this is reserved by ActiveRecord. 
  # If you use it, the record won't save
  belongs_to  :baseline_update, :class_name => 'Update', :foreign_key => 'update_id'
  
  validates_presence_of :user, :wiki, :page
  
  BODY_PATTERN = /<body.*<\/body>/m
  LINKS_PATTERN = /<a.*?href=".*?".*?<\/a>/
  HREF_PATTERN = /href="(.*?)"/

  DIFF_STYLE =   ["<style type=\"text/css\">",
"ins { text-decoration: none; background-color: #ff0; color: #000; }
del { text-decoration: line-through; color: #f00; }

div>ins, ul>ins, div>del, ul>del, body>ins, body>del { display: block; }",
"</style>"].join("\n")
  
  def previous_version
    case self.version
    when 0 then nil 
    when nil then self.page.current_version 
    else Version.find(:first, :conditions => ['page_id=? and version=?', self.page_id, self.version - 1])
    end
  end
  
  # TODO this doesn't add value
  def baseversion
    return Version.find(:first, :conditions => ['wiki_id = ? and page_id=? and version=0',
    self.wiki_id, self.page_id])
  end  
  
  def current_version
    return self.page.current_version
  end
  
  # return the latest version of page in a site
  def self.find_latest_version(site, page)
    return Version.find(:first ,:order => 'version DESC', :conditions => ["page_id=? and wiki_id =?", page.id, site.id])    
  end  
  
  # return the latest version based on a version
  # TODO use page.last_version
  def latest_version
    return Version.find(:first ,:order => 'version DESC', :conditions => ["page_id=? and wiki_id =?", self.page, self.wiki])    
  end
  
  # Returns relative path of a version in folder 'public', 
  # the column rel_path stores the relatieve path in a Site folder
    def rel_path_root
    return self.path.gsub("#{ENV['EPFWIKI_ROOT_DIR']}#{ENV['EPFWIKI_PUBLIC_FOLDER']}/", '')
  end
  
  # use #tidy to tidy the file using HTML Tidy. 
  # This also removes any empty lines that may have been 
  # created by PinEdit.
  def tidy
    logger.info("Tidying file " + path)
    Utils.tidy_file(path)
  end
  
  
  # method #html read or writes the HTML of a version from or to the version file.
  # When writing HTML Tidy is used to cleanup the file
  def html
    IO.readlines(self.path).join
  end

  # Create the tmp diff source file, clean it using Tidy and prepare for use with XHTMLDiff
  def html4diff(h = nil)
    logger.info("Create tmp diff source file #{self.path_to_tmp_diff_html} using #{self.path}")    
    FileUtils.copy(self.path, self.path_to_tmp_diff_html)
    Utils.tidy_file(self.path_to_tmp_diff_html)    
    h = IO.readlines(self.path_to_tmp_diff_html).join if h.nil?
    h = BODY_PATTERN.match(h)[0]
    h = h.gsub(Page::TREEBROWSER_PLACEHOLDER, '').gsub(Page::TREEBROWSER_PATTERN, '')
    h = h.gsub(Page::SHIM_TAG_PATTERN, Page::SHIM_TAG) # TODO remove? This should not be necessary, see html
    h = h.gsub(/<!-- epfwiki.*end -->/m, '') # TODO remove?
    h = h.gsub('</body>','').gsub(/<body.*>/, '')
    
    # If the html originates from TinyMCE it contains extra tbody tags.
    # TinyMCE adds those and this is good XHTML but if
    # we strip those so we get better diff results
    # Because without it, compare with the baseversion (not modified by TinyMCE) will 
    # result false positives (changes)
    h = h.gsub(/<[\/]{0,1}(tbody){1}[.]*>/, '') 
    
    # TODO Workaround for Tidy adding title attributes which causes false changes
    #--
    # The question mark makes it lazy, so it won't match for instance  
    # title="Org"></a><span class="overview" it will match
    # title="Org" only
    #++
    h = h.gsub(/title="(.*?)"/, '') # WE REMOVE ALL TITLE ATTRIBUTES FOR BETTER DIFFS
    logger.debug("html4diff #{self.path}: ")
    #logger.debug(h)
    file = File.new(self.path_to_tmp_diff_html, 'w')
    file.puts(h)
    file.close    
    h 
  end

  # Create diff results using XHTMLDiff
  def xhtmldiff(from_version)
    content_from = "<div>\n" + from_version.html4diff + "\n</div>"
    content_to = "<div>\n" + self.html4diff + "\n</div>"

    diff_doc = REXML::Document.new
    diff_doc << (div = REXML::Element.new 'div')
    hd = XHTMLDiff.new(div)
    
    parsed_from_content = REXML::HashableElementDelegator.new(REXML::XPath.first(REXML::Document.new(content_from), '/div'))
    parsed_to_content = REXML::HashableElementDelegator.new(REXML::XPath.first(REXML::Document.new(content_to), '/div'))
    Diff::LCS.traverse_balanced(parsed_from_content, parsed_to_content , hd)
    diffs = ''
    diff_doc.write(diffs, -1, true, true)
    diffs    
  end
  
  # Create diff file using #xhtmldiff. The file is generated if doesn't exist of if one of the versions is checked out.
  def xhtmldiffpage(from_version, force = false)
    p = path_to_diff(from_version)
      if !File.exists?(p) || !from_version.checkout.nil? || !self.checkout.nil? || force
      logger.info("Generating xhtmldiffpage #{p}")
      diffs = xhtmldiff(from_version)
      h = page.html
      body_tag = Page::BODY_TAG_PATTERN.match(h)[0]
      h = h.gsub(BODY_PATTERN,body_tag + diffs + '</body>')
      h = h.gsub('</head>',DIFF_STYLE + '</head>')
      h = h.gsub(Page::PAGE_HEAD_SNIPPET_PATTERN, '')
      file = File.new(p, 'w')
      file.puts(h)
      file.close
    end
  end
  
  # Absolute path to the diff file and paths to the intermediate (tidied, cleaned) HTML files
  def path_to_diff(from_version)
    return "#{ENV['EPFWIKI_ROOT_DIR']}#{ENV['EPFWIKI_PUBLIC_FOLDER']}/#{relpath_to_diff(from_version)}"
  end
  
  # Relative path to the diff file
  def relpath_to_diff(from_version)
    return '/' + self.wiki.rel_path + '/' + self.page.rel_path + "_EPFWIKI_DIFF_V#{from_version.version}_V#{self.version}.html"  
  end
  
  # Path intermediate (tidied, cleaned) HTML files, prepared for XHTMLDiff
  def path_to_tmp_diff_html
    FileUtils.makedirs(ENV['EPFWIKI_DIFFS_PATH']) unless File.exists?(ENV['EPFWIKI_DIFFS_PATH'])    
    "#{ENV['EPFWIKI_DIFFS_PATH']}#{self.id.to_s}.html"  
  end
  
  # Compares hrefs to determine new or added 
  #--
  # Depends on covert_urls settings of TinyMCE
  #++
  # TODO implement
  #def diff_links(from_version)
  #  links = self.html.scan(LINKS_PATTERN)
  #  links_from = from_version.html.scan(LINKS_PATTERN)
  #  hrefs = links.collect {|link | HREF_PATTERN.match(link)[0]}
  #  hrefs_from = links_from.collect {|link | HREF_PATTERN.match(link)[0]}
  #  new_removed = [hrefs - hrefs_from, hrefs_from - hrefs]
  #  new_removed
  #end
  
  # TODO implement
  #def diff_img(from_version)
  #end

  #def diff_area_links
  #end
   
  def template?
    self.wiki.title == 'Templates' 
  end
  
  def base_version?
    !user_version?
  end
  
  def user_version?
    baseline_process_id.nil?
  end
  
  # #version_text returns version number, site title and baseline,
  # for example <tt>1 from OpenUP(OUP_20060721)</tt>
  def version_text
    if self.base_version? 
      return self.version.to_s + ' from ' + self.wiki.title + ' (' + self.baseline_process.title+ ')'
    else
      return self.version.to_s + ' from ' + self.wiki.title + ' (' + self.user.name + ')'
    end
  end
  
  def delete_file
    logger.debug("Before Destroy: deleting file #{self.path}")
    File.delete(self.path)
  end
  
  # #uma_type_descr is used to retrieve the brief description for a template, see app/views/pages/new
  def uma_type_descr
    logger.debug("Returning uma_type_description from: #{self.inspect}")
    if self.note.blank? || self.note == 'Automatically created'
      match = /<table class="overviewTable".*?<td valign="top">(.*?)<\/td>/m.match(self.html)
      if match
        self.note = match[1]
        self.save!
        logger.info("Match found: #{self.note}")
      else
        logger.debug('No match')
      end
    end
    return self.note
  end
  
end
