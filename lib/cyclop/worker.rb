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
    # Number of jobs to process before exiting
    attr_accessor :die_after
    # Number of jobs processed by this worker
    attr_accessor :processed_jobs
    # Options passed to Cyclop.next to get next job
    attr_accessor :job_opts

    def initialize(config={})
      raise ArgumentError, 'mongo["database"] is required' unless config["mongo"] && config["mongo"]["database"]

      self.queues = config["queues"] || []
      self.logger = Logger.new(config["log_file"] || $stdout)
      self.sleep_interval = config["sleep_interval"] || 1
      self.actions = config["actions"] || "./actions"
      self.processed_jobs = 0
      self.die_after = config["die_after"]
      @job_opts = {}
      if config["limit_to_host"]
        @job_opts[:host] = config["limit_to_host"]
        @job_opts[:host] = Cyclop.host if @job_opts[:host]=="localhost"
      end
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
      register_signal_handlers
      loop do
        if stop?
          log "Shutting down..."
          break
        end
        if job = next_job
          @sleeping = false
          if @pid = fork
            msg = "Forked process #{@pid} to work on job #{job.queue}-#{job._id}..."
            log msg
            procline msg
            Process.wait
            log "Child process #{@pid} ended with status: #{$?}"
            self.processed_jobs += 1
            if $?.exitstatus==0
              job.complete!
            else
              job.release!
            end
          else
            procline "Processing #{job.queue}-#{job._id} (started at #{Time.now.utc})"
            exit! perform job
          end
        else
          log "No more job to process, start sleeping..." unless @sleeping
          @sleeping = true
          sleep sleep_interval
        end
      end
    end

    # Called inside forked process
    #
    # Parameters:
    #
    # * (Cyclop::Job) job - the job to process
    #
    def perform(job)
      load_actions
      Cyclop::Action.find_by_queue(job.queue).perform(*job.job_params)
      0
    rescue Exception => e
      log e.to_s
      job.release! e
      1
    end

    # Gracefull shutdown
    def stop
      @stop = true
    end

    # Forced shutdown
    def stop!
      if @pid
        Process.kill "TERM", @pid
        Process.wait
      end
      exit!
    end

  private

    # Trap signals
    #
    # QUIT - graceful shutdown
    # INT - first gracefull shutdown, second time force shutdown
    # TERM - force shutdown
    def register_signal_handlers
      trap("QUIT") { stop }
      trap("INT")  { @stop ? stop! : stop }
      trap("TERM") { stop! }
    end

    def next_job
      Cyclop.next *queues, job_opts
    end

    def procline(line)
      $0 = "cyclop-#{Cyclop::VERSION}: #{line}"
    end

    def log(message)
      logger << "#{Time.now}: #{message}\n"
    end

    def load_actions
      Dir["#{actions}/*.rb"].each{|action| require File.absolute_path(action) }
    end

    def stop?
      @stop || (die_after && processed_jobs >= die_after.to_i)
    end
  end
end