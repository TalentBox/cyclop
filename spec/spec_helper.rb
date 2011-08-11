require "bundler/setup"
require "logger"
require "cyclop"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each{|f| require f}

RSpec.configure do |config|
  config.before(:all) do
    logger = Logger.new "test.log"
    Cyclop.db = Mongo::Connection.new("localhost", nil, :logger => logger).db "cyclop_test#{RUBY_VERSION}"
  end
  config.before do
    Cyclop.db.collections.each(&:remove)
  end
end