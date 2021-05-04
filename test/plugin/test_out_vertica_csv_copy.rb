require "helper"
require "fluent/plugin/out_vertica_csv_copy.rb"

class VerticaCsvCopyOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::VerticaCsvCopyOutput).configure(conf)
  end
end
