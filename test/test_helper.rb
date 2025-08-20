# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "devise"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Helper module for i18n-aware validation testing
module ValidationTestHelper
  # Check if an attribute has a validation error (any error)
  def assert_validation_error(model, attribute)
    assert model.errors[attribute].present?, "Expected #{attribute} to have validation errors"
  end

  # Check if a model is invalid
  def assert_invalid(model, message = nil)
    assert_not model.valid?, message || "Expected model to be invalid"
  end
end

class ActiveSupport::TestCase
  include ValidationTestHelper
  include Devise::Test::IntegrationHelpers
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
