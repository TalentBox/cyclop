require "spec_helper"

describe Cyclop do
  describe ".push(opts={})" do
    it "creates a new Cyclop::Job initialized with opts" do
      opts = {}
      Cyclop::Job.should_receive :create, with: opts
      Cyclop.push opts
    end
  end
  describe ".next(*args)" do
    it "extracts queues from args" do
      Cyclop::Job.should_receive(:next).with(queues: [:email, "cache"], locked_by: Cyclop.send(:master_id))
      Cyclop.next :email, "cache"
    end
    it "extracts options from args" do
      Cyclop::Job.should_receive(:next).with(queues: [:email, "cache"], locked_by: "myid")
      Cyclop.next :email, "cache", locked_by: "myid"
    end
    it "extracts options from args even without queues" do
      Cyclop::Job.should_receive(:next).with(queues: [], locked_by: "myid")
      Cyclop.next locked_by: "myid"
    end
  end
  describe ".failed(opts={})" do
    it "extracts queues from args" do
      Cyclop::Job.should_receive(:failed).with(queues: [:email, "cache"])
      Cyclop.failed :email, "cache"
    end
    it "extracts options from args" do
      Cyclop::Job.should_receive(:failed).with(queues: [:email, "cache"], limit: 10)
      Cyclop.failed :email, "cache", limit: 10
    end
    it "extracts options from args even without queues" do
      Cyclop::Job.should_receive(:failed).with(queues: [], limit: 10)
      Cyclop.failed limit: 10
    end
  end
end