require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :slug_users do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :slugged_users do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :slug_user_histories do |t|
      t.integer :slug_user_id
      t.string :old_name
    end

    ActiveRecord::Base.connection.create_table :slugged_user_histories do |t|
      t.integer :slugged_user_id
      t.string :note
      t.string :name_before
      t.string :name_after
    end

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
    ActiveRecord::Base.connection.drop_table :slug_users
    ActiveRecord::Base.connection.drop_table :slugged_users
    ActiveRecord::Base.connection.drop_table :slug_user_histories
    ActiveRecord::Base.connection.drop_table :slugged_user_histories
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
    expect(history.old_name).to eq 'john'
    expect(history).not_to respond_to(:name_after)
  end

  it 'should be able to save with a hand-made before field named _before and no after field' do
    user = SluggedUser.create(:name => 'john')
    user.update_attributes(:name => 'john2')
    history = user.histories.first
    expect(history.name_before).to eq 'john'
    expect(history.name_after).to eq 'note'
  end

end
