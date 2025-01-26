require "rake"

RSpec.shared_context "rake" do
  before(:each) do
    # Load Rails application tasks
    Rails.application.load_tasks if defined?(Rails.application)

    # Clear any existing tasks
    Rake::Task.clear if defined?(Rake::Task)

    # Define environment task that rake tasks might depend on
    Rake::Task.define_task(:environment)
  end
end
