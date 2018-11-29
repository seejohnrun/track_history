require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :anon_users do |t|
      t.string :name
    end

    TrackHistory.disable_warnings
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
    expect(AnonUser).not_to respond_to(:historical_fields)
  end

end
