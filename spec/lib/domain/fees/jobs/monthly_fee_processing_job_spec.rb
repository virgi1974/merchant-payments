require "rails_helper"

RSpec.describe Domain::Fees::Jobs::MonthlyFeeProcessingJob, type: :job do
  include_context "rake"
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  describe "#perform" do
    let(:rake_task) { instance_double(Rake::Task) }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.application).to receive(:load_tasks)
      allow(Rake::Task).to receive(:[]).with("monthly_fees:process").and_return(rake_task)
      allow(rake_task).to receive(:invoke)
      allow(rake_task).to receive(:reenable)
    end

    it "processes monthly fees via rake task" do
      travel_to Time.zone.local(2024, 1, 1, 4, 0, 0) do
        expect(Rails.logger).to receive(:info).with("-------------------------------------------------------------------------").ordered
        expect(Rails.logger).to receive(:info).with("Starting MonthlyFeeProcessingJob at 2024-01-01 04:00:00 UTC").ordered
        expect(rake_task).to receive(:invoke).ordered
        expect(rake_task).to receive(:reenable).ordered
        expect(Rails.logger).to receive(:info).with("Finished MonthlyFeeProcessingJob at 2024-01-01 04:00:00 UTC").ordered
        expect(Rails.logger).to receive(:info).with("-------------------------------------------------------------------------").ordered

        described_class.perform_now
      end
    end
  end
end
