require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table drinks (id integer primary key auto_increment, name varchar(255))")
    ActiveRecord::Base.connection.execute("create table drink_histories (id integer primary key auto_increment, special varchar(255), name_before varchar(255), name_after varchar(255), created_at datetime)")
    class Drink < ActiveRecord::Base
      track_history :reference => false do
        annotate :something, :as => :special
      end
      def something
        'note'
      end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table drinks")
    ActiveRecord::Base.connection.execute("drop table drink_histories")
  end

  # clean up each time
  before(:each) do
    Drink.destroy_all
    Drink::History.destroy_all
  end

  it 'should be able to alias a field' do
    drink = Drink.create(:name => 'john')
    drink.update_attributes(:name => 'john2')
    Drink::History.first.respond_to?(:something).should == false
    Drink::History.first.special.should == 'note'
  end

end
