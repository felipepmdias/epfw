# http://railscasts.com/episodes/158-factories-not-fixtures

Factory.define :user do |f|
  f.sequence(:name) { |n| "foo#{n}" }
  f.ip_address "localhost"
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.hashed_password {|u| Utils.hash_pw(u.password)}
  f.email { |u| "foo#{u.name.downcase.gsub(' ', '.')}@epf.eclipse.org" }
  f.admin "Y"
  f.confirmed_on Time.now
end

#Factory.define :article do |f|
#  f.name "Foo"
#  f.association :user
#end
