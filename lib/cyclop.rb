require "mongo"
require "logger"
require "socket"

require "cyclop/job"
require "cyclop/worker"
require "cyclop/action"
require "cyclop/version"

module Cyclop
  extend self

  # Raised if db not set or connection error
  class DatabaseNotAvailable < StandardError; end
  # Raised if two actions share the same queue
  class ActionQueueClash < StandardError; end
  # Raised if no action has been found
  class NoActionFound < StandardError; end

  # Set which `Mongo::DB` to use
  def db=(db)
    @db = db
  end

  # Get `Mongo::DB` to use
  def db
    @db
  end

  # Get memoized host
  def host
    @host ||= Socket.gethostname
  end

  # Get a unique identifier for current process
  def master_id
    @master_id ||= "#{host}-#{Process.pid}-#{Thread.current}"
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
  # Returns a `Cyclop::Job`
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
  # Returns a `Cyclop::Job` or `nil` if nothing to process
  #
  def next(*args)
    opts = extract_opts! args
    Cyclop::Job.next({queues: args, locked_by: master_id}.merge opts)
  end

  # Get failed `Cyclop::Job`s
  #
  # Parameters:
  #
  #   * (Symbol, String) queues - list of queues to get a `Cyclop::Job` from. Defaults to all.
  #   * (Hash) opts (defaults to: {}) - a customizable set of options.
  #
  # Options Hash (opts):
  #
  #   * (String) :host - limit to `Cyclop::Job`s queued by this host.
  #   * (Integer) :skip (0) - number of `Cyclop::Job`s to skip.
  #   * (Integer) :limit (nil) - maximum number of `Cyclop::Job`s to return.
  #
  # Returns an `Array` of failed `Cyclop::Job`
  #
  def failed(*args)
    opts = extract_opts! args
    Cyclop::Job.failed({queues: args}.merge opts)
  end

private

  def extract_opts!(args)
    (args.pop if args.last.is_a?(Hash)) || {}
  end
end