# Templates
  
  def create_templates_baseline(folder = 'templates_20080828')
    Rails.logger.debug("Creating baseline #{folder}")
    cadmin = User.find_central_admin
    bp = BaselineProcess.new(:folder => folder, :title => folder, :user_id => cadmin.id)
    if File.exists?(bp.path)
      Rails.logger.debug('Removing old folder')
      FileUtils.rm_r(bp.path)
    end
    if !File.exists?(bp.path2zip)
      path = File.expand_path(File.dirname(__FILE__) + "/../data/#{bp.folder}.zip")
      Rails.logger.debug("Test" + File.dirname(bp.path2zip))
      FileUtils.makedirs(File.dirname(bp.path2zip))
      Rails.logger.debug("Copying #{path} to #{bp.path2zip}")
      FileUtils.copy(path, bp.path2zip) 
    end
    bp.unzip_upload
    bp.save!
    bp.scan4content
    return bp
  end
  
  def create_templates(bp = create_templates_baseline, folder = 'templates')
    Rails.logger.debug('Creating Templates Wiki')
    cadmin = User.find_central_admin
    wiki = Wiki.new(:folder => folder, :title => 'Templates', :user_id => cadmin.id)
    if File.exists?(wiki.path)
      Rails.logger.debug('Removing old folder')
      FileUtils.rm_r(wiki.path)
    end
    FileUtils.makedirs(File.dirname(wiki.path))
    wiki.save!
    update = Update.create(:wiki_id => wiki.id, :baseline_process_id => bp.id, :user_id => cadmin.id)
    update.do_update
    return wiki
  end
  
