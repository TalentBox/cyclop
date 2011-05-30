require "mongo"

require "socket"
require "cyclop/job"

module Cyclop
  extend self

  # Raised if db not set or connection error
  class DatabaseNotAvailable < StandardError; end

  # Sets which `Mongo::DB` to use
  def db=(db)
    @db = db
  end

  def db
    @db
  end

  # Get memoized host
  def host
    @host ||= Socket.gethostname
  end

  # Queues a new job
  #
  #   Minimum usage:
  #
  #     Cyclop.push queue: "refresh_cache"
  #
  #   With `:job_params`:
  #
  #     # with an `Array`
  #     Cyclop.push queue: "email", job_params: ["1", :welcome]
  #
  #     # with a `Hash`
  #     Cyclop.push queue: "email", job_params: {user_id: "1",
  #     type: "welcome"}
  #
  #   With `:delay`:
  #
  #     # Will not perform the task before a delay of 60 seconds
  #     Cyclop.push queue: "email", delay: 60
  #
  #   With `:retries` and `:splay`:
  #
  #     # Will mark the task as failed only after 3 retries
  #     Cyclop.push queue: "email", retries: 3
  #
  #     # Will mark the task as failed only after 2 retries
  #     # and 30 seconds between each retry
  #     Cyclop.push queue: "email", retries: 2, splay: 30
  #
  # Parameters:
  #
  #   * (Hash) opts (defaults to: {}) - a customizable set of options. The minimum required is :queue.
  #
  # Options Hash (opts):
  #
  #   * (Symbol, String) :queue - name of the queue (required).
  #   * (Array, Hash) :job_params (nil) - parameters to send to the `Cyclop::Job#perform` method.
  #   * (Integer) :delay (0) - time to wait in `seconds` before the task should be performed.
  #   * (Integer) :retries (0) - number of retries before the `Cyclop::Job` is marked as failed.
  #   * (Integer) :splay (60) - time to wait in `seconds` between retry.
  #   * (String) :host (Cyclop.host) - host under which the `Cyclop::Job` should be added.
  #
  def push(opts={})
    Cyclop::Job.create opts
  end

  # Get a `Cyclop::Job` to process
  #
  # Parameters:
  #
  #   * (Symbol, String) queues - list of queues to get a `Cyclop::Job` from. Defaults to all.
  #   * (Hash) opts (defaults to: {}) - a customizable set of options.
  #
  # Options Hash (opts):
  #
  #   * (String) :host - limit to `Cyclop::Job`s queued by this host.
  #
  def next(*args)
  end

  # Get failed `Cyclop::Job`s
  #
  # Parameters:
  #
  #   * (Hash) opts (defaults to: {}) - a customizable set of options.
  #
  # Options Hash (opts):
  #
  #   * (Integer) :skip (0) - number of `Cyclop::Job`s to skip.
  #   * (Integer) :limit (nil) - maximum number of `Cyclop::Job`s to return.
  #
  def failed(*args)
  end

  # Get a failed `Cyclop::Job` to process
  #
  # Parameters:
  #
  #   * (Symbol, String) args - list of queues to get a `Cyclop::Job` from. Defaults to all.
  #   * (Hash) opts (defaults to: {}) - a customizable set of options.
  #
  # Options Hash (opts):
  #
  #   * (String) :host - limit to `Cyclop::Job`s queued by this host.
  #
  def next_failed(*args)
  end

  # Spawn a `Cyclop::Worker`
  #
  # Parameters:
  #
  #   * (Symbol, String) args - list of queues to get `Cyclop::Job` from. Defaults to all.
  #   * (Hash) opts (defaults to: {}) - a customizable set of options.
  #
  # Options Hash (opts):
  #
  #   * (String) :host - limit to `Cyclop::Job`s queued by this host.
  #
  def spawn(*args)
  end
end