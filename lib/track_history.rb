module TrackHistory

  autoload :VERSION, File.join(File.dirname(__FILE__), 'track_history', 'version')
  require 'rubygems'
  require 'active_record'

  def self.install
    ActiveRecord::Base.send(:include, self)
  end

  def self.included(base)
    base.extend ActsAsMethods
    base.send(:include, InstanceMethods)
  end

  module ActsAsMethods

    # Make a model historical
    # Takes a hash of options, which can only be :model_name to force a different model name
    # Default model name is ModelHistory
    def track_history(options = {}, &block)
      options.assert_valid_keys(:model_name, :table_name, :reference)
      define_historical_model(self, options[:model_name], options[:table_name], options.has_key?(:reference) ? !!options[:reference] : true, &block)
    end

    def historical_class
      @klass_reference
    end

    private

    def define_historical_model(base, model_name, table_name, track_reference, &block)

      # figure out the model name
      model_name ||= "#{base.name}History"
      @klass_reference = Object.const_set(model_name, Class.new(ActiveRecord::Base))
      @klass_reference.send(:table_name=, table_name) unless table_name.nil?

      unless @klass_reference.table_exists?
        STDERR.puts "[TrackHistory] No such table exists: #{@klass_reference.table_name}"
        return
      end
 
      # get the history class in line
      @klass_reference.send(:extend, HistoryMethods)

      # infer fields
      @klass_reference.columns_hash.each_key do |k| 
        matches = k.match(/(.+?)_before$/)
        if matches && matches.size == 2 && field_name = matches[1]
          next if @klass_reference.historical_fields.has_key?(field_name) # override inferrences
          @klass_reference.historical_fields[field_name] = { :before => "#{field_name}_before".to_sym, :after => "#{field_name}_after".to_sym }
        end
      end
 
      # figure out the field for tracking action (enum)
      @klass_reference.instance_variable_set(:@historical_action_field, @klass_reference.columns_hash.has_key?('action') ? 'action' : nil)
      @klass_reference.instance_variable_set(:@track_historical_reference, track_reference) 

      # allow other things to be specified
      @klass_reference.module_eval(&block) if block_given?
      
      # create the history class
      rel = base.name.singularize.underscore.downcase.to_sym
      @klass_reference.send(:include, HistoricalRelationHelpers)

      # create a backward reference
      if track_reference
        @klass_reference.belongs_to rel
        @klass_reference.send(:alias_method, :historical_relation, rel)
        has_many :histories, :class_name => model_name, :order => 'created_at desc, id desc' if track_reference
      end

      # tell the other class about us
      # purposely don't define these until after getting historical_fields
      before_update { |c| c.send(:record_historical_changes, 'update') }

      # track other things (optionally)
      unless @klass_reference.historical_action_field.nil?
        after_create { |c| c.send(:record_historical_changes, 'create') }
        before_destroy { |c| c.send(:record_historical_changes, 'destroy') }
      end

    end

  end

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
      field_s = field.is_a?(String) ? field : field.to_s
      historical_fields[field_s] = { 
        :before => options[:before] || "#{field}_before".to_sym,
        :after => options[:after] || "#{field}_after".to_sym
      }
      nil
    end

    def annotate(field, options = {}, &block) # haha
      options.assert_valid_keys(:as)
      save_as = options.has_key?(:as) ? options[:as] : field

      unless columns_hash.has_key?(save_as.to_s)
        raise ActiveRecord::StatementInvalid.new("No such attribute '#{field}' on #{@klass_reference.name}")
      end

      historical_tracks[save_as] = block.nil? ? field : block
    end

  end

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

  module InstanceMethods

    private

    def record_historical_changes(action)
      historical_fields = self.class.historical_class.historical_fields
      historical_tracks = self.class.historical_class.historical_tracks
      return if historical_fields.empty? && historical_tracks.empty?
      # go through each and build the hashes
      attributes = {}
      historical_fields.each do |field, field_options|
        next if !send(:"#{field}_changed?") && action == 'update'
        after_value = action == 'destroy' ? nil : send(field.to_sym) # special tracking on deletions
        attributes.merge! field_options[:before] => send(:"#{field}_was"), field_options[:after] => after_value
      end
      return if attributes.empty? && action == 'update' # nothing changed - skip out 
      # then go through each track
      historical_tracks.each do |field, block|
        attributes[field] = block.is_a?(Symbol) ? send(block) : (block.arity == 1 ? block.call(self) : instance_eval(&block)) # give access to the user object
      end
      # determine the action_type if needed
      if action_field = self.class.historical_class.historical_action_field
        attributes[action_field] = action
      end
      # record the change
      if self.class.historical_class.track_historical_reference?
        self.histories.create(attributes)
      else
        self.class.historical_class.create(attributes)
      end
    end

  end

end

TrackHistory::install
