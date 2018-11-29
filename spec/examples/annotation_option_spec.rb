require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :drinks do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :drink_histories do |t|
      t.integer :drink_id
      t.string :name_before
      t.string :name_after
      t.string :special
    end

    class Drink < ActiveRecord::Base
      track_history :reference => false do
        annotate :something, :as => :special
      end
      def something
        'note'
      end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :drinks
    ActiveRecord::Base.connection.drop_table :drink_histories
  end

  # clean up each time
  before(:each) do
    Drink.destroy_all
    Drink::History.destroy_all
  end

  it 'should be able to alias a field' do
    drink = Drink.create(:name => 'john')
    drink.update_attributes(:name => 'john2')
    expect(Drink::History.first).not_to respond_to(:something)
    expect(Drink::History.first.special).to eq 'note'
  end

end
