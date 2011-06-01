module Cyclop
  class Worker
    # Queues to process
    attr_accessor :queues
    # Logger for master
    attr_accessor :logger
    # How much time to sleep between poll
    attr_accessor :sleep_interval
    # Path to actions directory
    attr_accessor :actions

    def initialize(config={})
      raise ArgumentError, 'mongo["database"] is required' unless config["mongo"] && config["mongo"]["database"]

      self.queues = config["queues"] || []
      self.logger = Logger.new(config["log_file"] || $stdout)
      self.sleep_interval = config["sleep_interval"] || 1
      self.actions = config["actions"] || "./actions"
      connection = if config["mongo"]["hosts"]
        Mongo::ReplSetConnection.new(
          *config["mongo"]["hosts"],
          rs_name: config["mongo"]["rs_name"],
          read_secondary: !!config["mongo"]["read_secondary"],
          logger: (logger if config["mongo"]["log"]),
        )
      else
        Mongo::Connection.new(
          (config["mongo"]["host"] || "127.0.0.1"),
          (config["mongo"]["port"] || 27017),
          logger: (logger if config["mongo"]["log"]),
        )
      end
      Cyclop.db = connection.db config["mongo"]["database"]
    end

    # Start processing jobs
    def run
      trap("SIGINT") { @stop = true }
      loop do
        if @stop
          log "Shutting down..."
          break
        end
        if job = next_job
          @sleeping = false
          before_fork job
          if @pid = fork
            log "Forked process #{@pid} to work on job #{job._id}..."
            Process.wait
            log "Child process #{@pid} ended with status: #{$?}"
            after_fork job, $?.exitstatus
          else
            exit perform job
          end
        else
          log "No more job to process, start sleeping..." unless @sleeping
          @sleeping = true
          sleep sleep_interval
        end
      end
    end

    # Called before forking a new process
    #
    # This is intended to be overriden
    #
    # Parameters:
    #
    # * (Cyclop::Job) job - the job to process
    #
    def before_fork(job)
    end

    # Called inside forked process
    #
    # This is intended to be overriden
    #
    # Parameters:
    #
    # * (Cyclop::Job) job - the job to process
    #
    def perform(job)
      load_actions
      log job.inspect
      Cyclop::Action.find_by_queue(job.queue).perform(*job.job_params)
      0
    rescue Exception
      log $!.to_s
      job.release! $!
      1
    end

    # Called after forked process has exited
    #
    # This is intended to be overriden
    #
    # Parameters:
    #
    # * (Cyclop::Job) job - the job to process
    # * (Integer) status - forked process exit status
    #
    def after_fork(job, status)
      if status==0
        job.complete!
      else
        job.release!
      end
    end

  private

    def next_job
      Cyclop.next *queues
    end

    def procline(line)
      $0 = "cyclop-#{Cyclop::VERSION}: #{line}"
    end

    def log(message)
      logger << "#{Time.now}: #{message}\n"
    end
    
    def load_actions
      Dir["#{actions}/*.rb"].each{|action| require action}
    end
  end
end