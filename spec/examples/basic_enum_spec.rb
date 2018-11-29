require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :basic_users do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :basic_user_histories do |t|
      t.integer :basic_user_id
      t.string :name_before
      t.string :name_after
      t.string :action
    end

    class BasicUser < ActiveRecord::Base
      track_history
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :basic_users
    ActiveRecord::Base.connection.drop_table :basic_user_histories
  end

  # clean up each time
  before(:each) do
    BasicUser.destroy_all
    BasicUser::History.destroy_all
  end

  it 'should record an action on create when there is an action field' do
    user = BasicUser.create(:name => 'john')
    history = user.histories.first
    expect(history.action).to eq 'create'
    expect(history.name_before).to be_nil
    expect(history.name_after).to eq 'john'
  end

  it 'should record an action on update when there is an action field' do
    user = BasicUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')

    history = user.histories.first
    expect(history.action).to eq 'update'
    expect(history.name_before).to eq 'john'
    expect(history.name_after).to eq 'john2'
  end

  it 'should record an action on destroy when there is an action field' do
    user = BasicUser.create(:name => 'john')
    user.destroy

    history = user.histories.order(:id => 'desc').first
    expect(history.basic_user_id).to eq user.id # make sure the reference is maintained
    expect(history.action).to eq 'destroy'
    expect(history.name_before).to eq 'john'
    expect(history.name_after).to be_nil # we do this for convenience
    expect(history.modifications).to eq ['name']
  end

end
