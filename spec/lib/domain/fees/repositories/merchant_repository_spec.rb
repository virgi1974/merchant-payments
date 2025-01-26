require "rails_helper"

RSpec.describe Domain::Fees::Repositories::MerchantRepository do
  describe "#find_all_merchants_in_batches" do
    let(:repository) { described_class.new }
    let(:merchant_model) { described_class::MERCHANT_MODEL }
    let(:batch_size) { described_class::BATCH_SIZE }

    it "delegates to merchant model with correct batch size" do
      expect(merchant_model).to receive(:find_each).with(batch_size: batch_size)
      repository.find_all_merchants_in_batches
    end
  end
end
