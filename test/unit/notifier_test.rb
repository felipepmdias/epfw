require 'test_helper'

class EpfcLibraryTest < ActiveSupport::TestCase
  
  # TODO include all record types: 
  test "Delivery summary" do
    @george = Factory(:user, :name => 'George Shapiro', :password => 'secret', :admin => 'C')
    @andy = Factory(:user, :name => 'Andy Kaufman', :password => 'secret', :admin => 'Y')
    @tony = Factory(:user, :name => 'Tony Clifton', :password => 'secret', :admin => 'N')
    @oup_20060721 = create_oup_20060721
    @oup_wiki = create_oup_wiki(@oup_20060721)
    assert_not_nil @oup_wiki
    page = WikiPage.find_by_filename('artifact,_fdRfkBUJEdqrUt4zetC1gg.html')
    assert_not_nil page
    #date_previous_week = date - 7.days
    #puts "Previous week: #{date_previous_week}"
    #start_of_previous_week = (date - 7.days).at_beginning_of_week
    #start_of_week = date.at_beginning_of_week
    #puts "Previous week: from #{start_of_previous_week} to #{start_of_week}"
    #puts "Previous day from #{(Time.now - 1.day).at_beginning_of_day} to #{Time.now.at_beginning_of_day}"
    #puts "Previous month #{(Time.now - 1.month).at_beginning_of_month} to #{Time.now.at_beginning_of_month}"
    comment1 = Comment.new(:user => @andy, :text => 'some text', :page => page, :site => @oup_wiki, :version => page.versions[0])
    comment1.created_on = Time.now - 3.days
    assert comment1.save!
    page = WikiPage.find_by_filename('artifact,_fdRfkBUJEdqrUt4zetC1gg.html')
    checkout = Checkout.new(:user => @andy, :page => page, :site => @oup_wiki, :note => 'Checkout to test notifier')
    assert checkout.save! 
    assert Checkout.count > 0
    assert Comment.count > 0
    starttime = Time.now.at_beginning_of_month
    endtime = (Time.now + 1.month).at_beginning_of_month
    @tony.created_on = Time.now - 3.days
    @tony.save!
    assert 0 < User.find(:all, :conditions => ['created_on > ? and created_on < ?', starttime, endtime ], :order => 'created_on DESC').size
    Notifier.summary({:type => 'M', :dummy => ''}, Time.now + 1.month).deliver # plus 1 month, because records are created in the current month
  end
  
end
