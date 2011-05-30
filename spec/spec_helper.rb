require "bundler/setup"

require "cyclop"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each{|f| require f}

RSpec.configure do |config|
  config.before(:all) do
    Cyclop.db = Mongo::Connection.new["cyclop_test"]
  end
  config.before do
    Cyclop.db.collections.each(&:remove)
  end
end