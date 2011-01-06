require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table model_users (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table table_users (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table model_user_audits (id integer primary key auto_increment, model_user_id integer, name_before varchar(256), name_after varchar(256), created_at datetime)")
    ActiveRecord::Base.connection.execute("create table table_user_audits (id integer primary key auto_increment, table_user_id integer, name_before varchar(256), name_after varchar(256), created_at datetime)")
    class ModelUser < ActiveRecord::Base
      track_history :model_name => 'ModelUserAudit'
    end
    class TableUser < ActiveRecord::Base
      track_history :table_name => 'table_user_audits'
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table table_users")
    ActiveRecord::Base.connection.execute("drop table model_users")
    ActiveRecord::Base.connection.execute("drop table table_user_audits")
    ActiveRecord::Base.connection.execute("drop table model_user_audits")
  end

  # clean up each time
  before(:each) do
    ModelUser.destroy_all
    TableUser.destroy_all
  end

  it 'should work still with a modified model name' do
    user = ModelUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.size.should == 1
    user.histories.first.should be_a(ModelUserAudit)
  end

  it 'should work still with a modified table name' do
    user = TableUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.size.should == 1
    user.histories.first.should be_a(TableUserHistory) # shouldn't change
  end

end

