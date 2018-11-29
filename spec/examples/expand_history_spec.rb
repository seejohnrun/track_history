require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :doors do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :door_histories do |t|
      t.integer :door_id
      t.string :name_before
      t.string :name_after
    end

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
    ActiveRecord::Base.connection.drop_table :doors
    ActiveRecord::Base.connection.drop_table :door_histories
  end

  # clean up each time
  before(:each) do
    Door.destroy_all
    Door::History.destroy_all
  end

  it 'should be able to define class methods' do
    expect(Door::History.class_note).to eq 'class_note'
  end

  it 'should be able to define instance methods' do
    door = Door.create(:name => 'john')
    door.update_attributes(:name => 'john2')
    expect(Door::History.first.instance_note).to eq 'instance_note'
  end

  it 'should not have historical_fields as an instance method' do
    door = Door.create(:name => 'john')
    door.update_attributes(:name => 'john2')
    expect(Door::History.first).not_to respond_to(:historical_fields)
  end

end
