require "rails_helper"

RSpec.describe DomainEvent do
  describe "base class" do
    let(:loan) { create(:lending_loan) }
    let(:user) { create(:user) }

    it "requires aggregate and actor" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "raises NotImplementedError for replay" do
      event = described_class.new(aggregate: loan, actor: user)
      expect { event.replay(loan) }.to raise_error(NotImplementedError)
    end
  end
end
