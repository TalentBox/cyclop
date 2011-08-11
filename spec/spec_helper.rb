require "bundler/setup"
require "logger"
require "cyclop"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each{|f| require f}

RSpec.configure do |config|
  config.before(:all) do
    logger = Logger.new "test.log"
    db_name = "cyclop_test#{RUBY_VERSION.gsub(".", "_")}"
    Cyclop.db = Mongo::Connection.new("localhost", nil, :logger => logger).db db_name
  end
  config.before do
    Cyclop.db.collections.each(&:remove)
  end
end