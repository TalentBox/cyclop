require "spec_helper"

describe Cyclop::Worker do
  subject { Cyclop::Worker.new({"mongo" => {"database" => "cyclop_test"}}) }

  its(:queues){ should be_empty }
  its(:logger){ should_not be_nil }
  its(:sleep_interval){ should == 1 }
  its(:actions){ should == "./actions" }

  it "raise ArgumentError without mongo['database']" do
    lambda {
      Cyclop::Worker.new
    }.should raise_error ArgumentError, 'mongo["database"] is required'
  end

  describe "#perform" do
    let(:worker) do
      Cyclop::Worker.new({
        "mongo" => {"database" => "cyclop_test"},
        "actions" => File.expand_path("../../fixtures/actions", __FILE__),
      }) 
    end
    let(:job) { Cyclop.push queue: "slow", job_params: ["tony@starkenterprises.com", :welcome] }
    it "loads actions files" do
      lambda { Cyclop::Spec::Action::Email }.should raise_error NameError
      worker.perform job
      lambda { Cyclop::Spec::Action::Email }.should_not raise_error
    end
    it "calls perform on action class with specified params" do
      require File.expand_path("../../fixtures/actions/email", __FILE__)
      Cyclop::Spec::Action::Email.should_receive(:perform).with("tony@starkenterprises.com", :welcome)
      worker.perform job
    end
  end
  
  describe "#run" do
    let(:worker) do
      Cyclop::Worker.new({
        "log_file" => File.expand_path("../../../test.log", __FILE__),
        "mongo" => {"database" => "cyclop_test"},
        "actions" => File.expand_path("../../fixtures/actions", __FILE__),
      }) 
    end
    context "with successful action" do
      it "remove the job" do
        job = Cyclop.push queue: "slow", job_params: ["tony@starkenterprises.com", :welcome]
        t = Thread.new { worker.run }
        sleep 1
        worker.stop
        t.join
        Cyclop::Job.find(job._id).should be_nil
      end
    end

    context "with failing action" do
      it "mark the job as failed" do
        job = Cyclop.push queue: "slow", job_params: ["tony@starkenterprises.com"]
        t = Thread.new { worker.run }
        sleep 1
        worker.stop
        t.join
        job.reload.failed.should be_true
      end

      it "mark the job as failed after retry" do
        job = Cyclop.push queue: "slow", job_params: ["tony@starkenterprises.com"], retries: 1, splay: 0
        t = Thread.new { worker.run }
        sleep 1
        worker.stop
        t.join
        job.reload
        job.failed.should be_true
        job.attempts.should == 2
      end
    end
    
    context "limiting to jobs queued by a given host" do
      let(:host) { "test.local" }
      let(:worker) do
        Cyclop::Worker.new({
          "log_file" => File.expand_path("../../../test.log", __FILE__),
          "mongo" => {"database" => "cyclop_test"},
          "actions" => File.expand_path("../../fixtures/actions", __FILE__),
          "limit_to_host" => host,
        }) 
      end
      it "run only jobs from this host" do
        job = Cyclop.push queue: "slow", job_params: ["tony@starkenterprises.com", :welcome]
        job_local = Cyclop.push queue: "slow", job_params: ["tony@starkenterprises.com", :welcome], host: host
        2.times do
          t = Thread.new { worker.run }
          sleep 1
          worker.stop
          t.join
        end
        job.reload
        job.attempts.should == 0
        Cyclop::Job.find(job_local._id).should be_nil
      end
    end
  end
end