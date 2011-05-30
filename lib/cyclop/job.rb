module Cyclop
  class Job
    # Unique identifier
    attr_accessor :id
    # Queue name
    attr_accessor :queue
    # Parameters sent to `#perform`
    attr_accessor :job_params
    # Delay in seconds
    attr_accessor :delay
    # Number of retries before being marked as failed
    attr_accessor :retries
    # Time in seconds between retry
    attr_accessor :splay
    # Host it's added under
    attr_accessor :created_by
    # Time it was created
    attr_accessor :created_at
    # Time it was last updated
    attr_accessor :updated_at
    # Worker unique identifier
    attr_accessor :locked_by
    # Time when worker started
    attr_accessor :locked_at
    # Number of unsuccessful attempts
    attr_accessor :attempts
    # Backtraces of unsuccessful attempts
    attr_accessor :errors

    def initialize(opts={})
      raise ArgumentError, ":queue is required" unless opts[:queue]
      self.queue = opts[:queue]
      self.job_params = opts[:job_params]
      self.delay = opts[:delay] || 0
      self.retries = opts[:retries] || 0
      self.splay = opts[:splay] || 60
      self.created_by = opts[:host] || Cyclop.host
      self.attempts = 0
      self.errors = []
    end

    # Create a new job and save it to the queue specified in `opts[:queue]`
    def self.create(opts={})
      job = new opts
      job.save
      job
    end

    # Save to queue
    def save
      self.updated_at = Time.now
      if persisted?
        raise NotImplementedError
      else
        self.created_at = updated_at
        self.id = collection.insert attributes, safe: true
      end
      true
    rescue Mongo::OperationFailure
      false
    end

    def reload
      doc = collection.find_one id
      attributes.each{|attr, _| send "#{attr}=", doc[attr.to_s]}
      self
    end

    # If we have an id the object is persisted
    def persisted?
      !!self.id
    end

  private
    def collection
      @collection ||= Cyclop.db ? 
        Cyclop.db["cyclop_jobs"] : raise(Cyclop::DatabaseNotAvailable)
    end
    
    def attributes
      {
        queue: queue,
        job_params: job_params,
        delay: delay,
        retries: retries,
        splay: splay,
        created_by: created_by,
        created_at: created_at,
        updated_at: updated_at,
        locked_by: locked_by,
        locked_at: locked_at,
        attempts: attempts,
        errors: errors,
      }
    end

  end
end