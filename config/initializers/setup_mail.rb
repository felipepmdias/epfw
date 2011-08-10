# ActionMailer will use sendmail if it’s set up on your machine but 
# here we can instead specify SMTP settings in this initializer
ActionMailer::Base.smtp_settings = {  
  :address              => "smtp.gmail.com",  
  :port                 => 587,  
  :domain               => "epf.eclipse.org",  
  :user_name            => "onno.van.der.straaten@gmail.com",  
  :password             => "****",  
  :authentication       => "plain",  
  :enable_starttls_auto => true  
}
#ActionMailer::Base.delivery_method = :test