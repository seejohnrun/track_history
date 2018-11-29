require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :model_users do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :model_user_audits do |t|
      t.integer :model_user_id
      t.string :name_before
      t.string :name_after
    end

    ActiveRecord::Base.connection.create_table :table_users do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :table_user_audits do |t|
      t.integer :table_user_id
      t.string :name_before
      t.string :name_after
    end

    class ModelUser < ActiveRecord::Base
      track_history :model_name => 'ModelUserAudit'
    end
    class TableUser < ActiveRecord::Base
      track_history :table_name => 'table_user_audits'
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :table_users
    ActiveRecord::Base.connection.drop_table :model_users
    ActiveRecord::Base.connection.drop_table :table_user_audits
    ActiveRecord::Base.connection.drop_table :model_user_audits
  end

  # clean up each time
  before(:each) do
    ModelUser.destroy_all
    TableUser.destroy_all
  end

  it 'should work still with a modified model name' do
    user = ModelUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.size).to eq 1
    expect(user.histories.first).to be_a(ModelUserAudit)
  end

  it 'should work still with a modified table name' do
    user = TableUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.size).to eq 1
    expect(user.histories.first).to be_a(TableUser::History) # shouldn't change
  end

end
