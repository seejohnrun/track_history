require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  NOTE = 'some text'

  before(:all) do
    ActiveRecord::Base.connection.execute("create table complex_users (id integer primary key auto_increment, name varchar(256), email varchar(255))")
    ActiveRecord::Base.connection.execute("create table complex_user_histories (id integer primary key auto_increment, complex_user_id integer, name_before varchar(256), name_after varchar(256), email_before varchar(255), email_after varchar(255), note varchar(255), note2 varchar(255), created_at datetime)")
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
    ActiveRecord::Base.connection.execute("drop table complex_users")
    ActiveRecord::Base.connection.execute("drop table complex_user_histories")
  end

  # clean up each time
  before(:each) do
    ComplexUser.destroy_all
    ComplexUserHistory.destroy_all
  end

  it 'should automatically annotate with a note on changes' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.first.note.should == NOTE
    user.histories.first.note2.should == "hello old john"
  end 

  it 'should only affect one field when updating one field, the other should be nil' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    
    user.histories.first.name_before.should == 'john'
    user.histories.first.name_after.should == 'john2' 
    user.histories.first.email_before.should == nil
    user.histories.first.email_after.should == nil
  end

  it 'should have the proper modifications when updating 1/2 fields' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.first.modifications.should == ['name']
  end
    
  it 'should have the proper modifications when updating 2/2 fields' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2', :email => 'foo@foo.com')
    user.histories.first.modifications.sort.should == ['email', 'name']
  end

  it 'should have a good to_s for one field modifications' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    user.histories.first.to_s.should == 'modified name on user: john2'
  end

  it 'should have a good to_s for two field modifications' do
    user = ComplexUser.create(:name => 'john', :email => 'foo@foo.com')
    user.update_attributes(:name => 'john2', :email => 'foo2@foo2.com')
    user.histories.first.to_s.should == 'modified email, name on user: john2'
  end

  it 'should have a good to_s when moving to nil' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:email => 'foo@foo.com')
    user.histories.first.to_s.should == 'modified email on user: john'
  end

  it 'should be able to take a field from nil to something and record that' do
    user = ComplexUser.create(:name => 'john')
    user.update_attributes(:email => 'foo@foo.com')
    user.histories.first.email_before.should == nil
    user.histories.first.email_after.should == 'foo@foo.com'
  end

end
