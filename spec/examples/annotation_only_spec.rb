require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table beers (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table beer_histories (id integer primary key auto_increment, name_before varchar(256), name_after varchar(256), created_at datetime, john varchar(256))")
    class Beer < ActiveRecord::Base
      track_history :reference => false do
        annotate :john
      end
      def john; 'hi'; end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table beers")
    ActiveRecord::Base.connection.execute("drop table beer_histories")
  end

  # clean up each time
  before(:each) do
    Beer.destroy_all
    Beer::History.destroy_all
  end

  it 'should not need a reference column in order to record histories' do
    user = Beer.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.respond_to?(:histories).should == false

    history = Beer::History.first
    history.modifications.should == ['name']
    history.name_before.should == 'john'
    history.name_after.should == 'john2'
    history.john.should == 'hi'
    history.respond_to?(:user).should == false
    history.respond_to?(:historical_relation).should == false
  end

end
