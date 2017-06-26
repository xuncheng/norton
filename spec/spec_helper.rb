require "simplecov"
require "active_record"
require "nulldb"
require "norton"
require "rspec"
require "timecop"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter
]

SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.order = :random

  # Clean Up Redis
  config.before(:each) do
    Norton.redis.with { |conn| conn.flushdb }
  end
end

Norton.setup url: "redis://localhost:6379/0"

ActiveRecord::Base.establish_connection :adapter => :nulldb
