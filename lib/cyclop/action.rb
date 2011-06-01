module Cyclop
  class Action
    @@actions = Set.new
    def self.inherited(klass)
      @@actions << klass
    end

    def self.find_by_queue(queue)
      actions = @@actions.select{|action| action.queues.include? queue }
      if @@actions.empty?
        raise Cyclop::NoActionFound, "No action defined"
      elsif actions.empty?
        queues = @@actions.collect(&:queues).flatten.uniq.collect(&:inspect)
        raise Cyclop::NoActionFound, "No action found for #{queue.inspect} queue. Valid queues: #{queues.join(", ")}"
      elsif actions.size>1
        raise Cyclop::ActionQueueClash, "\"#{queue}\" queue belongs to multiple actions: #{actions.collect{|a| a.name}.join(", ")}"
      else
        actions.first
      end
    end

    def self.queues
      []
    end

    def self.perform(*args)
      raise NotImplementedError
    end

    def self.to_s
      "#{name}: #{queues.inspect}"
    end
  end
end