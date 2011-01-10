require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table users (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table user_histories (id integer primary key auto_increment, user_id integer, name_before varchar(256), name_after varchar(256), created_at datetime)")
    class User < ActiveRecord::Base
      validates_length_of :name, :minimum => 2
      track_history
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table users")
    ActiveRecord::Base.connection.execute("drop table user_histories")
  end

  # clean up each time
  before(:each) do
    User.destroy_all
    UserHistory.destroy_all
  end

  it 'should know its own historical fields' do
    User.historical_fields.should == ['name']
  end

  it 'should be able to get the user from :user' do
    user = User.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.first.user == user
  end

  it 'should get the same object when asking for :user or :historical_relation' do
    user = User.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    history = user.histories.first
    # check
    history.user.should_not == nil
    history.historical_relation.object_id.should == history.user.object_id
  end

  it 'should be able to track changes on a simple user model with one field' do
    # create a user
    user = User.create(:name => 'john')
    # change the name
    user.name = 'john2'
    user.save
    # check
    user.histories.first.name_before.should == 'john'
    user.histories.first.name_after.should == 'john2'
  end

  it 'should be able to accurately list modifications - 1 column' do
    user = User.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.first.modifications.should == ['name']
  end

  it 'should not create histories when creating a new object' do
    user = User.create(:name => 'john')
    user.histories.size.should == 0
  end

  it 'should not create histories when nothing has changes' do
    user = User.create(:name => 'john')
    user.touch
    user.histories.size.should == 0
  end

  it 'should not create histories when something changed to the same value' do
    user = User.create(:name => 'john')
    user.name = 'john'
    user.save
    user.histories.size.should == 0
  end

  it 'should not update when validations fail' do
    user = User.create(:name => 'john')
    user.name = 'j'
    user.save
    user.histories.size.should == 0
  end

  it 'should be able to work with two user records at the same time and not get confused' do
    user1 = User.create(:name => 'john')
    user2 = User.create(:name => 'kate')
    
    user1.update_attributes(:name => 'john2')
    user2.update_attributes(:name => 'kate2')

    user1.histories.size.should == 1
    user1.histories.first.name_before.should == 'john'
    user1.histories.first.name_after.should == 'john2'

    user2.histories.size.should == 1
    user2.histories.first.name_before.should == 'kate'
    user2.histories.first.name_after.should == 'kate2'
  end
  
  it 'should work with dependent => destroy appropriately' do
    user = User.create(:name => 'john')
    user_id = user.id
    user.update_attributes(:name => 'john2')
    user.histories.size.should == 1

    User.destroy_all
    UserHistory.count.should == 1
    UserHistory.first.user_id.should == user_id
  end

end
