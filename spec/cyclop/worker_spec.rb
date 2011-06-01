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

  describe "#run" do
    
  end
end