require "spec_helper"

describe Cyclop do
  describe ".push(opts={})" do
    it "creates a new Cyclop::Job initialized with opts" do
      opts = {}
      Cyclop::Job.should_receive :create, with: opts
      Cyclop.push opts
    end
  end
end