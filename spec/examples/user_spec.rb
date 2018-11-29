require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :users do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :user_histories do |t|
      t.integer :user_id
      t.string :name_before
      t.string :name_after
    end

    class User < ActiveRecord::Base
      validates_length_of :name, :minimum => 2
      track_history
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table users")
    ActiveRecord::Base.connection.execute("drop table user_histories")
  end

  # clean up each time
  before(:each) do
    User.destroy_all
    User::History.destroy_all
  end

  it 'should be able to get the user from :user' do
    user = User.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.first.user).to eq user
  end

  it 'should get the same object when asking for :user or :historical_relation' do
    user = User.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    history = user.histories.first
    # check
    expect(history.user).not_to eq nil
    expect(history.historical_relation.object_id).to eq history.user.object_id
  end

  it 'should be able to track changes on a simple user model with one field' do
    # create a user
    user = User.create(:name => 'john')
    # change the name
    user.name = 'john2'
    user.save
    # check
    expect(user.histories.first.name_before).to eq 'john'
    expect(user.histories.first.name_after).to eq 'john2'
  end

  it 'should be able to accurately list modifications - 1 column' do
    user = User.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.first.modifications).to eq ['name']
  end

  it 'should not create histories when creating a new object' do
    user = User.create(:name => 'john')
    expect(user.respond_to?(:historical_fields)).to eq false
    expect(user.histories.size).to eq 0
  end

  it 'should not create histories when nothing has changes' do
    user = User.create(:name => 'john')
    user.touch
    expect(user.histories.size).to eq 0
  end

  it 'should not create histories when something changed to the same value' do
    user = User.create(:name => 'john')
    user.name = 'john'
    user.save
    expect(user.histories.size).to eq 0
  end

  it 'should not update when validations fail' do
    user = User.create(:name => 'john')
    user.name = 'j'
    user.save
    expect(user.histories.size).to eq 0
  end

  it 'should be able to work with two user records at the same time and not get confused' do
    user1 = User.create(:name => 'john')
    user2 = User.create(:name => 'kate')

    user1.update_attributes(:name => 'john2')
    user2.update_attributes(:name => 'kate2')

    expect(user1.histories.size).to eq 1
    expect(user1.histories.first.name_before).to eq 'john'
    expect(user1.histories.first.name_after).to eq 'john2'

    expect(user2.histories.size).to eq 1
    expect(user2.histories.first.name_before).to eq 'kate'
    expect(user2.histories.first.name_after).to eq 'kate2'
  end

  it 'should work with dependent => destroy appropriately' do
    user = User.create(:name => 'john')
    user_id = user.id
    user.update_attributes(:name => 'john2')
    expect(user.histories.size).to eq 1

    User.destroy_all
    expect(User::History.count).to eq 1
    expect(User::History.first.user_id).to eq user_id
  end

end
