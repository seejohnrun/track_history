require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => '')

    TrackHistory.disable_warnings
    class AnonAdmin < ActiveRecord::Base
      validates_length_of :name, :minimum => 2
      track_history
    end
  end

  after(:all) do
    ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'track_history')
  end


  it 'should not error out when there is no table for a history model' do
    AnonAdmin.should_not respond_to(:historical_fields)
  end

end
