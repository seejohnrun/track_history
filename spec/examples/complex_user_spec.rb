require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  NOTE = 'some text'

  before(:all) do
    ActiveRecord::Base.connection.create_table :complex_users do |t|
      t.string :name
      t.string :email
    end

    ActiveRecord::Base.connection.create_table :complex_user_histories do |t|
      t.integer :complex_user_id
      t.string :note
      t.string :note2
      t.string :name_before
      t.string :name_after
      t.string :email_before
      t.string :email_after
    end

    class ComplexUser < ActiveRecord::Base
      validates_length_of :name, :minimum => 2
      track_history do
        annotate :note
        annotate(:note2) { "hello old #{name_was}" }
      end
      def note; NOTE; end
      def to_s; "user: #{name}"; end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :complex_users
    ActiveRecord::Base.connection.drop_table :complex_user_histories
  end

  # clean up each time
  before(:each) do
    ComplexUser.destroy_all
    ComplexUser::History.destroy_all
  end

  it 'should automatically annotate with a note on changes' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.first.note).to eq NOTE
    expect(user.histories.first.note2).to eq "hello old john"
  end

  it 'should only affect one field when updating one field, the other should be nil' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')

    expect(user.histories.first.name_before).to eq 'john'
    expect(user.histories.first.name_after).to eq 'john2'
    expect(user.histories.first.email_before).to be_nil
    expect(user.histories.first.email_after).to be_nil
  end

  it 'should have the proper modifications when updating 1/2 fields' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.first.modifications).to eq ['name']
  end

  it 'should have the proper modifications when updating 2/2 fields' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2', :email => 'foo@foo.com')
    expect(user.histories.first.modifications.sort).to eq ['email', 'name']
  end

  it 'should have a good to_s for one field modifications' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    expect(user.histories.first.to_s).to eq 'modified name on user: john2'
  end

  it 'should have a good to_s for two field modifications' do
    user = ComplexUser.create(:name => 'john', :email => 'foo@foo.com')
    user.update_attributes(:name => 'john2', :email => 'foo2@foo2.com')
    expect(user.histories.first.to_s).to eq 'modified email, name on user: john2'
  end

  it 'should have a good to_s when moving to nil' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:email => 'foo@foo.com')
    expect(user.histories.first.to_s).to eq 'modified email on user: john'
  end

  it 'should be able to take a field from nil to something and record that' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:email => 'foo@foo.com')
    expect(user.histories.first.email_before).to be_nil
    expect(user.histories.first.email_after).to eq 'foo@foo.com'
  end

end
