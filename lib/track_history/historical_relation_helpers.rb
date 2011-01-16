module TrackHistory

  module HistoricalRelationHelpers

    # Get a list of the modifications in a given history
    def modifications
      self.class.historical_fields.reject do |field, options|
        send(options[:before]) == send(options[:after])
      end.keys
    end

    def to_s
      return 'modified nothing' if modifications.empty?
      str = 'modified ' + modifications.sort.join(', ')
      str += " on #{historical_relation}" if self.class.instance_variable_get(:@track_historical_reference)
      str
    end

  end

end
