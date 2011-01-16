module TrackHistory

  module HistoryMethods

    attr_reader :historical_fields, :historical_action_field

    def track_historical_reference?
      @track_historical_reference
    end

    def historical_fields
      @historical_fields ||= {}
    end

    def historical_tracks
      @historical_tracks ||= {}
    end

    def field(field, options = {})
      options.assert_valid_keys(:before, :after)
      field_s = field.is_a?(String) ? field : field.to_s
      historical_fields[field_s] = { 
        :before => options[:before] || nil,
        :after => options[:after] || nil
      }
      nil
    end

    def annotate(field, options = {}, &block) # haha
      options.assert_valid_keys(:as)
      save_as = options.has_key?(:as) ? options[:as] : field

      unless columns_hash.has_key?(save_as.to_s)
        raise ActiveRecord::StatementInvalid.new("No such attribute '#{save_as}' on #{self.name}")
      end

      historical_tracks[save_as] = block.nil? ? field : block
    end

  end

end
