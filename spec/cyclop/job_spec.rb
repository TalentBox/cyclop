require "spec_helper"

describe Cyclop::Job do
  subject { Cyclop::Job.new queue: "demo" }

  its(:queue){ should == "demo" }
  its(:job_params){ should be_nil }
  its(:delay){ should == 0 }
  its(:delayed_until){ should be_nil }
  its(:retries){ should == 0 }
  its(:splay){ should == 60 }
  its(:created_by){ should == Cyclop.host }
  its(:created_at){ should be_nil }
  its(:updated_at){ should be_nil }
  its(:locked_by){ should be_nil }
  its(:locked_at){ should be_nil }
  its(:failed){ should be false }
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

  describe "next(opts={})" do
    it do
      lambda {
        Cyclop::Job.next
      }.should raise_error ArgumentError, "locked_by is required"
    end
    context "with no job in queue" do
      it "returns nil" do
        Cyclop::Job.next(locked_by: "myid").should be_nil
      end
    end
    context "with jobs in queue" do
      let(:email_job_delayed) { Cyclop::Job.create queue: "email", delay: 3600 }
      let(:email_job_failed) { Cyclop::Job.create queue: "email", failed: true }
      let(:email_job_no_retry) { Cyclop::Job.create queue: "email", attempts: 1 }
      let(:email_job_locked) { Cyclop::Job.create queue: "email", locked_at: Time.now.utc-10 }
      let(:email_job_next) { Cyclop::Job.create queue: "email" }
      let(:email_job_other_host) { Cyclop::Job.create queue: "email", created_by: "demo.local" }
      let(:snail_mail_job_stalling) { Cyclop::Job.create queue: "snail mail", locked_at: Time.now.utc-3000 }

      before do
        email_job_delayed
        email_job_failed
        email_job_no_retry
        email_job_next
        email_job_other_host
        snail_mail_job_stalling
      end

      it "returns the first job to process when called without queue" do
        Cyclop::Job.next(locked_by: "myid").should == email_job_next
      end

      it "increments attempts" do
        Cyclop::Job.next(locked_by: "myid").attempts.should == 1
      end

      it "locks to given id" do
        Cyclop::Job.next(locked_by: "myid").locked_by.should == "myid"
      end

      it "sets locked_at" do
        Cyclop::Job.next(locked_by: "myid").locked_at.should_not be_nil
      end

      it "returns the first job to process when called with :email queue" do
        Cyclop::Job.next(queues: [:email], locked_by: "myid").should == email_job_next
      end

      it "returns the first job to process for a given host" do
        Cyclop::Job.next(queues: [:email], locked_by: "myid", host: "demo.local").should == email_job_other_host
      end

      it "returns nil when called with :cache queue" do
        Cyclop::Job.next(queues: [:cache], locked_by: "myid").should be_nil
      end

      it "unlock and returns job stalled for a long time" do
        Cyclop::Job.next(queues: ["snail mail"], locked_by: "myid").should == snail_mail_job_stalling
      end
    end
  end
  describe "failed(opts={})" do
    context "with no job in queue" do
      it "returns an empty array" do
        Cyclop::Job.failed.should == []
      end
    end
    context "with jobs in queue" do
      let(:email_job_failed) { Cyclop::Job.create queue: "email", failed: true }
      let(:cache_job_no_retry) { Cyclop::Job.create queue: "cache", attempts: 1 }
      let(:cache_job_failed) { Cyclop::Job.create queue: "cache", failed: true }
      let(:email_job_next) { Cyclop::Job.create queue: "email" }

      before do
        email_job_failed
        cache_job_no_retry
        cache_job_failed
        email_job_next
      end

      it "returns all failed jobs when called without queue" do
        Cyclop::Job.failed.should == [email_job_failed, cache_job_no_retry, cache_job_failed]
      end

      it "returns all failed job to process when called with :email queue" do
        Cyclop::Job.failed(queues: [:email]).should == [email_job_failed]
      end

      it "returns empty array when called with :snail_mail queue" do
        Cyclop::Job.failed(queues: [:snail_mail]).should == []
      end

      it "respect :skip and :limit options" do
        Cyclop::Job.failed(skip: 1, limit: 1).should == [cache_job_no_retry]
      end
    end
  end
end