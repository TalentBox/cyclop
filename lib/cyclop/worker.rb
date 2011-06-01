module Cyclop
  class Worker
    # Queues to process
    attr_accessor :queues
    # Logger for master
    attr_accessor :logger
    # How much time to sleep between poll
    attr_accessor :sleep_interval

    def initialize(config={})
      self.queues = config["queues"] || []
      self.sleep_interval = config["sleep_interval"] || 1
      self.logger = Logger.new(config["log_file"] || $stdout)
      connection = if config["mongodb"]["hosts"]
        Mongo::ReplSetConnection.new(
          *config["mongodb"]["hosts"],
          rs_name: config["mongodb"]["rs_name"],
          read_secondary: !!config["mongodb"]["read_secondary"],
          logger: (logger if config["mongodb"]["log"]),
        )
      else
        Mongo::Connection.new(
          config["mongodb"]["host"],
          config["mongodb"]["port"],
          logger: (logger if config["mongodb"]["log"]),
        )
      end
      Cyclop.db = connection.db config["mongo"]["database"]
    end

    # Start processing jobs
    def run
      trap("SIGINT") { @stop = true }
      loop do
        break if @stop
        if job = next_job
          before_fork job
          if @pid = fork
            logger << "#{Time.now}: Forked process #{@pid} to work on job #{job.id}..."
            Process.wait
            logger << "#{Time.now}: Child process #{@pid} ended with status: #{$?.exitstatus}"
            after_fork job, $?.exitstatus
          else
            exit perform job
          end
        else
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
    end

  private

    def next_job
      Cyclop.next queues
    end
    
    def procline(line)
      $0 = "cyclop-#{Cyclop::VERSION}: #{line}"
    end
  end
end