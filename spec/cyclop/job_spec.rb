require "spec_helper"

describe Cyclop::Job do
  subject { Cyclop::Job.new queue: "demo" }

  its(:queue){ should == "demo" }
  its(:job_params){ should be_nil }
  its(:delay){ should == 0 }
  its(:retries){ should == 0 }
  its(:splay){ should == 60 }
  its(:created_by){ should == Cyclop.host }
  its(:created_at){ should be_nil }
  its(:updated_at){ should be_nil }
  its(:locked_by){ should be_nil }
  its(:locked_at){ should be_nil }
  its(:attempts){ should == 0 }
  its(:errors){ should == [] }

  describe "#save" do
    it "raises a Cyclop::DatabaseNotAvailable if no db defined" do
      old, Cyclop.db = Cyclop.db, nil
      lambda {
        Cyclop::Job.new(queue: "demo").save
      }.should raise_error Cyclop::DatabaseNotAvailable
      Cyclop.db = old
    end
    context "on create" do
      it "saves the job" do
        subject.save.should be_true
        subject.should be_persisted
        subject.reload.queue.should == "demo"
      end
    end
    context "on update" do
      pending
    end
  end

  describe ".create(opts={})" do
    it do
      lambda {
        Cyclop::Job.create
      }.should raise_error ArgumentError, ":queue is required"
    end
    it "returns a persisted job on success" do
      job = Cyclop::Job.create queue: "demo"
      job.should be_persisted
    end
  end
end