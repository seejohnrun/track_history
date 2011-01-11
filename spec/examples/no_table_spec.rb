require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table anon_users (id integer primary key auto_increment, name varchar(256))")
    class AnonUser < ActiveRecord::Base
      validates_length_of :name, :minimum => 2
      track_history
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table anon_users")
  end
  
  before(:each) do
    AnonUser.destroy_all
  end

  it 'should not error out when there is no table for a history model' do
    AnonUser.should_not respond_to(:historical_fields)
  end

end
