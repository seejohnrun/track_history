require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table basic_users (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table basic_user_histories (id integer primary key auto_increment, basic_user_id integer, name_before varchar(256), name_after varchar(256), action enum ('create', 'destroy', 'update'), created_at datetime)")
    class BasicUser < ActiveRecord::Base
      track_history
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table basic_users")
    ActiveRecord::Base.connection.execute("drop table basic_user_histories")
  end

  # clean up each time
  before(:each) do
    BasicUser.destroy_all
    BasicUserHistory.destroy_all
  end

  it 'should record an action on create when there is an action field' do
    user = BasicUser.create(:name => 'john')
    history = user.histories.first
    history.action.should == 'create'
    history.name_before.should == nil
    history.name_after.should == 'john'
  end

  it 'should record an action on update when there is an action field' do
    user = BasicUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')

    history = user.histories.first
    history.action.should == 'update'
    history.name_before.should == 'john'
    history.name_after.should == 'john2'
  end

  it 'should record an action on destroy when there is an action field' do
    user = BasicUser.create(:name => 'john')
    user.destroy

    history = user.histories.order('id desc').first
    history.basic_user_id.should == user.id # make sure the reference is maintained
    history.action.should == 'destroy'
    history.name_before.should == 'john'
    history.name_after.should == nil # we do this for convenience
    history.modifications.should == ['name']
  end

end
