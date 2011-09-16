module TrackHistory

  require 'rubygems'
  require 'active_record'

  autoload :VERSION, 'track_history/version'
  autoload :HistoryMethods, 'track_history/history_methods'
  autoload :HistoricalRelationHelpers, 'track_history/historical_relation_helpers'

  def self.install
    ActiveRecord::Base.send(:include, self)
  end

  def self.warnings_disabled?
    @warnings_disabled ||= false
  end

  def self.disable_warnings
    @warnings_disabled = true
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
      model_name ||= "#{base.name}::History"
      class_path = model_name.split(/::/)
      inner_name = class_path.pop
      outer = class_path.inject(Object) { |outer, inner_name| outer.const_get(inner_name) }
      @klass_reference = outer.const_set(inner_name, Class.new(ActiveRecord::Base))
      @klass_reference.send(:table_name=, table_name) unless table_name.nil?

      unless @klass_reference.table_exists?
        $stderr.puts "[TrackHistory] No such table exists: #{@klass_reference.table_name} - #{self.name} history will not be tracked" unless TrackHistory.warnings_disabled?
        return
      end
 
      # get the history class in line
      @klass_reference.send(:extend, TrackHistory::HistoryMethods)
 
      # figure out the field for tracking action (enum)
      @klass_reference.instance_variable_set(:@historical_action_field, @klass_reference.columns_hash.has_key?('action') ? 'action' : nil)
      @klass_reference.instance_variable_set(:@track_historical_reference, track_reference) 

      # allow other things to be specified
      @klass_reference.module_eval(&block) if block_given?

      # infer fields
      @klass_reference.columns_hash.each_key do |k| 
        matches = k.match(/(.+?)_before$/)
        if matches && matches.size == 2 && field_name = matches[1]
          next if @klass_reference.historical_fields.has_key?(field_name) || @klass_reference.historical_tracks.has_key?(field_name) # override inferrences
          @klass_reference.historical_fields[field_name] = { :before => "#{field_name}_before".to_sym, :after => "#{field_name}_after".to_sym }
        end
      end
      
      # create the history class
      rel = base.name.singularize.underscore.downcase.to_sym
      @klass_reference.send(:include, TrackHistory::HistoricalRelationHelpers)

      # create a backward reference
      if track_reference
        @klass_reference.belongs_to rel
        @klass_reference.send(:alias_method, :historical_relation, rel)
        has_many :histories, :class_name => model_name, :order => 'id desc' if track_reference
      end

      # tell the other class about us
      # purposely don't define these until after getting historical_fields
      before_update :record_historical_changes

      # track other things (optionally)
      unless @klass_reference.historical_action_field.nil?
        after_create :record_historical_changes_on_create
        before_destroy :record_historical_changes_on_destroy
      end

    end

  end

  module InstanceMethods

    private

    def record_historical_changes_on_destroy
      record_historical_changes('destroy')
    end

    def record_historical_changes_on_create
      record_historical_changes('create')
    end

    def record_historical_changes(action = 'update')
      historical_fields = self.class.historical_class.historical_fields
      historical_tracks = self.class.historical_class.historical_tracks
      return if historical_fields.empty? && historical_tracks.empty?
      # go through each and build the hashes
      attributes = {}
      historical_fields.each do |field, field_options|
        next if !send(:"#{field}_changed?") && action == 'update'
        attributes[field_options[:after]] = (action == 'destroy' ? nil : send(field.to_sym)) if field_options[:after] # special tracking on deletions
        attributes[field_options[:before]]  = send(:"#{field}_was") if field_options[:before]
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
