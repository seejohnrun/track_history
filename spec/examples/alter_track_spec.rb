require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :things do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :thing_histories do |t|
      t.string :name_from
      t.string :name_to
      t.timestamp :created_at
      t.string :john
    end

    class Thing < ActiveRecord::Base
      track_history :reference => false do
        field :name, :before => :name_from, :after => :name_to
      end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :things, force: :cascade
    ActiveRecord::Base.connection.drop_table :thing_histories, force: :cascade
  end

  # clean up each time
  before(:each) do
    Thing.destroy_all
    Thing::History.destroy_all
  end

  it 'should work with altered column names' do
    thing = Thing.create(:name => 'john')
    thing.name = 'john2'
    thing.save!
    history = Thing::History.first
    history.modifications.should == ['name']
    history.name_from.should == 'john'
    history.name_to.should == 'john2'
    history.respond_to?(:name_before).should == false
    history.respond_to?(:name_after).should == false
  end

end
