require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.execute("create table slug_users (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table slugged_users (id integer primary key auto_increment, name varchar(256))")
    ActiveRecord::Base.connection.execute("create table slug_user_histories (id integer primary key auto_increment, slug_user_id integer, old_name varchar(256), created_at datetime)")
    ActiveRecord::Base.connection.execute("create table slugged_user_histories (id integer primary key auto_increment, slugged_user_id integer, name_before varchar(256), name_after varchar(256), created_at datetime)")
    class SlugUser < ActiveRecord::Base
      track_history do
        field :name, :before => :old_name
      end
    end
    class SluggedUser < ActiveRecord::Base
      track_history do
        field :name, :before => :name_before
        annotate :note, :as => :name_after
      end
      def note
        'note'
      end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.execute("drop table slug_users")
    ActiveRecord::Base.connection.execute("drop table slugged_users")
    ActiveRecord::Base.connection.execute("drop table slug_user_histories")
    ActiveRecord::Base.connection.execute("drop table slugged_user_histories")
  end

  # clean up each time
  before(:each) do
    SlugUser.destroy_all
    SluggedUser.destroy_all
    SlugUser::History.destroy_all
    SluggedUser::History.destroy_all
  end
  
  # use case for slugs
  it 'should be able to save with just one of the before / after fields' do
    user = SlugUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    history = user.histories.first
    history.old_name.should == 'john'
    history.should_not respond_to(:name_after)
  end

  it 'should be able to save with a hand-made before field named _before and no after field' do
    user = SluggedUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    history = user.histories.first
    history.name_before.should == 'john'
    history.name_after.should == 'note'
  end

end

