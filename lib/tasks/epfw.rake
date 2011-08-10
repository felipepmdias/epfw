  # To see all available tasks run from app root:
  # rake --tasks 
  namespace :epfw do
    # To update a wikis using a job run from a cron job:
    # rake epfw:update RAILS_ENV=production
    desc "Update EPF Wiki sites"
    task :update => :environment  do
      puts "Running update in #{Rails.env}"
      Site.update
    end # end task update
    # To update a wikis using a job run from a cron job:
    # rake epfw:update RAILS_ENV=production    
    desc "Send EPF Wiki reports"
    task :reports => :environment do
      puts "Running update in #{Rails.env}"
      puts "EPFWIKI_HOST=#{ENV['EPFWIKI_HOST']}"
      Site.reports
    end # end task send_reports
  end # end namespace