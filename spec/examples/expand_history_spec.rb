require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table doors (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table door_histories (id integer primary key auto_increment, door_id integer, name_before varchar(256), name_after varchar(256), created_at datetime)")
    class Door < ActiveRecord::Base
      track_history do
        def self.class_note
          'class_note'
        end
        def instance_note
          'instance_note'
        end
      end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table doors")
    ActiveRecord::Base.connection.execute("drop table door_histories")
  end

  # clean up each time
  before(:each) do
    Door.destroy_all
    DoorHistory.destroy_all
  end

  it 'should be able to define class methods' do
    DoorHistory.class_note.should == 'class_note'
  end

  it 'should be able to define instance methods' do
    door = Door.create(:name => 'john')
    door.update_attributes(:name => 'john2')
    DoorHistory.first.instance_note.should == 'instance_note'
  end
  
  it 'should not have historical_fields as an instance method' do
    door = Door.create(:name => 'john')
    door.update_attributes(:name => 'john2')
    DoorHistory.first.should_not respond_to(:historical_fields)
  end

end

