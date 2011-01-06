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
    def track_history(options = {})
      @historical_fields = []
      @historical_tracks = {}
      define_historical_model(self, options[:model_name])
      yield if block_given?
    end

    def annotate(field, &block) # haha
      @historical_tracks ||= []
      @historical_tracks[field] = block
      unless @klass_reference.columns_hash.has_key?(field.is_a?(Symbol) ? field.to_s : field) 
        raise ActiveRecord::StatementInvalid.new("No such attribute '#{field}' on #{@klass_reference.name}")
      end
    end

    def historical_fields
      @historical_fields
    end

    def historical_tracks
      @historical_tracks
    end

    private

    def define_historical_model(base, class_name)

      class_name ||= "#{base.name}History"
      klass = Object.const_set(class_name, Class.new(ActiveRecord::Base))
      @klass_reference = klass
     
      # infer fields
      klass.columns_hash.each_key do |k| 
        matches = k.match(/(.+?)_before$/)
        if matches && matches.size == 2 && field_name = matches[1]
          @historical_fields << field_name if klass.columns_hash.has_key?("#{field_name}_after")
        end
      end
     
      # create the history class
      rel = base.name.singularize.underscore.downcase.to_sym
      klass.belongs_to rel
      klass.send(:alias_method, :historical_relation, rel)
      klass.send(:include, HistoricalHelpers)

      # tell the other class about us
      # purposely don't define these until after getting historical_fields
      has_many :histories, :class_name => class_name, :order => 'created_at desc', :dependent => :destroy
      before_update :record_historical_changes

    end

  end

  module HistoricalHelpers

    # Get a list of the modifications in a given history
    def modifications
      historical_relation.class.historical_fields.reject do |field|
        send(:"#{field}_before") == send(:"#{field}_after")
      end
    end

    def to_s
      modifications.map do |field|
        "#{field}: " + send(:"#{field}_before") + '=>' + send(:"#{field}_after")
      end.join(', ')
    end

  end

  module InstanceMethods

    private

    def record_historical_changes
      return if self.class.historical_fields.empty?
      # go through each and build the hashes
      attributes = {}
      self.class.historical_fields.each do |field|
        next unless send(:"#{field}_changed?")
        attributes.merge! :"#{field}_before" => send(:"#{field}_was"), :"#{field}_after" => send(field.to_sym)
      end
      return if attributes.empty? # nothing changed - skip out 
      # then go through each track
      self.class.historical_tracks.each do |field, block|
        attributes[field] = block.nil? ? send(field) : (block.arity == 1 ? block.call(self) : instance_eval(&block)) # give access to the user object
      end
      self.histories.create(attributes)
    end

  end

end

TrackHistory::install
