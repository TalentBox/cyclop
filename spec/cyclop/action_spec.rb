require "spec_helper"

describe Cyclop::Action do
  describe ".find_by_queue(queue)" do
    context "with no subclass" do
      it "raises an Cyclop::NoActionFound" do
        lambda {
          Cyclop::Action.find_by_queue("email")
        }.should raise_error Cyclop::NoActionFound, "No action defined"
      end
    end
    context "with subclasses" do
      before :all do
        class EmailAction < Cyclop::Action
          def self.queues
            ["email", "email_welcome"]
          end
        end
        class CacheAction < Cyclop::Action
          def self.queues
            ["cache"]
          end
        end
      end
      it "returns only action matching queue" do
        Cyclop::Action.find_by_queue("email").should be EmailAction
      end
      it "returns nil if no action match queue" do
        lambda {
          Cyclop::Action.find_by_queue("compress")
        }.should raise_error Cyclop::NoActionFound, 'No action found for "compress" queue. Valid queues: "email", "email_welcome", "cache"'
      end
      it "raises an error if two actions share the same queue" do
        class EmailCacheAction < Cyclop::Action
          def self.queues
            ["email", "cache"]
          end
        end
        lambda {
          Cyclop::Action.find_by_queue "email"
        }.should raise_error Cyclop::ActionQueueClash, '"email" queue belongs to multiple actions: EmailAction, EmailCacheAction'
        Object.send :remove_const, :EmailCacheAction
      end
    end
  end
end