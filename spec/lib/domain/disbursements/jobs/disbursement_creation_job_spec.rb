require "rails_helper"

module Domain
  module Disbursements
    module Jobs
      RSpec.describe DisbursementCreationJob do
        include_context "rake"

        describe "#perform" do
          let(:job) { described_class.new }
          let(:rake_task) { double("Rake::Task") }

          before do
            allow(::Rake::Task).to receive(:[]).with("disbursements:create").and_return(rake_task)
            allow(rake_task).to receive(:invoke)
            allow(rake_task).to receive(:reenable)
            allow(Rails.logger).to receive(:info)
          end

          it "invokes and reenables the disbursements:create rake task" do
            job.perform

            expect(rake_task).to have_received(:invoke).once
            expect(rake_task).to have_received(:reenable).once
          end

          it "logs the start and end of the job" do
            Timecop.freeze(Time.utc(2024, 1, 15, 8, 0, 0)) do # 8:00 UTC
              job.perform

              expect(Rails.logger).to have_received(:info).with(/Starting DisbursementCreationJob at 2024-01-15 08:00:00 UTC/)
              expect(Rails.logger).to have_received(:info).with(/Finished DisbursementCreationJob at 2024-01-15 08:00:00 UTC/)
            end
          end

          context "when rake task fails" do
            before do
              allow(rake_task).to receive(:invoke).and_raise(StandardError.new("Rake task failed"))
            end

            it "logs the error and re-raises it" do
              expect(Rails.logger).to receive(:info).with(/Starting DisbursementCreationJob/)
              expect { job.perform }.to raise_error(StandardError, "Rake task failed")
            end
          end
        end
      end
    end
  end
end
