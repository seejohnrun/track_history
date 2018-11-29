require File.dirname(__FILE__) + '/spec_helper'

describe TrackHistory do

  before(:all) do
    ActiveRecord::Base.connection.create_table :beers do |t|
      t.string :name
    end

    ActiveRecord::Base.connection.create_table :beer_histories do |t|
      t.string :name_before
      t.string :name_after
      t.timestamp :created_at
      t.string :john
    end

    class Beer < ActiveRecord::Base
      track_history :reference => false do
        annotate :john
      end
      def john; 'hi'; end
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :beers, force: :cascade
    ActiveRecord::Base.connection.drop_table :beer_histories, force: :cascade
  end

  # clean up each time
  before(:each) do
    Beer.destroy_all
    Beer::History.destroy_all
  end

  it 'should not need a reference column in order to record histories' do
    user = Beer.create(:name => 'john')
    user.name = 'john2'
    user.save!
    expect(user.respond_to?(:histories)).to eq false

    history = Beer::History.first
    expect(history.modifications).to eq ['name']
    expect(history.name_before).to eq 'john'
    expect(history.name_after).to eq 'john2'
    expect(history.john).to eq 'hi'
    expect(history).not_to respond_to(:user)
    expect(history).not_to respond_to(:historical_relation)
  end

end
