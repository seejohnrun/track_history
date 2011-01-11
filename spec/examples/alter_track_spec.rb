require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table things (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table thing_histories (id integer primary key auto_increment, name_from varchar(256), name_to varchar(256), created_at datetime, john varchar(256))")
    class Thing < ActiveRecord::Base
      track_history :reference => false do
        field :name, :before => :name_from, :after => :name_to
      end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table things")
    ActiveRecord::Base.connection.execute("drop table thing_histories")
  end

  # clean up each time
  before(:each) do
    Thing.destroy_all
    ThingHistory.destroy_all
  end

  it 'should work with altered column names' do
    thing = Thing.create(:name => 'john')
    thing.update_attributes(:name => 'john2')
    history = ThingHistory.first
    history.modifications.should == ['name']
    history.name_from.should == 'john'
    history.name_to.should == 'john2'
    history.respond_to?(:name_before).should == false
    history.respond_to?(:name_after).should == false
  end

end
