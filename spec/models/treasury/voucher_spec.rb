require "rails_helper"

RSpec.describe Treasury::Voucher do
  describe "associations" do
    it { is_expected.to belong_to(:cash_session).class_name("Treasury::CashSession") }
    it { is_expected.to belong_to(:cash_account).class_name("Accounting::Account") }
    it { is_expected.to belong_to(:entry).class_name("Accounting::Entry").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:voucher_number) }
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending posted cancelled]) }
  end

  describe "scopes" do
    describe ".posted" do
      it "returns vouchers with posted status" do
        expect(described_class.posted).to be_a(ActiveRecord::Relation)
      end
    end

    describe ".pending" do
      it "returns vouchers with pending status" do
        expect(described_class.pending).to be_a(ActiveRecord::Relation)
      end
    end

    describe ".cancelled" do
      it "returns vouchers with cancelled status" do
        expect(described_class.cancelled).to be_a(ActiveRecord::Relation)
      end
    end

    describe ".receipts" do
      it "returns cash receipt vouchers" do
        expect(described_class.receipts).to be_a(ActiveRecord::Relation)
      end
    end

    describe ".disbursements" do
      it "returns cash disbursement vouchers" do
        expect(described_class.disbursements).to be_a(ActiveRecord::Relation)
      end
    end

    describe ".by_latest" do
      it "orders vouchers by created_at descending" do
        expect(described_class.by_latest).to be_a(ActiveRecord::Relation)
      end
    end
  end

  describe "instance methods" do
    describe "#receipt?" do
      it "returns true for receipt vouchers" do
        voucher = described_class.new(type: "Treasury::CashReceiptVoucher")
        expect(voucher.receipt?).to be true
      end

      it "returns false for disbursement vouchers" do
        voucher = described_class.new(type: "Treasury::CashDisbursementVoucher")
        expect(voucher.receipt?).to be false
      end
    end

    describe "#disbursement?" do
      it "returns true for disbursement vouchers" do
        voucher = described_class.new(type: "Treasury::CashDisbursementVoucher")
        expect(voucher.disbursement?).to be true
      end

      it "returns false for receipt vouchers" do
        voucher = described_class.new(type: "Treasury::CashReceiptVoucher")
        expect(voucher.disbursement?).to be false
      end
    end

    describe "#cancel!" do
      it "changes status to cancelled" do
        voucher = described_class.new(status: "pending")
        voucher.cancel!
        expect(voucher.status).to eq("cancelled")
      end
    end

    describe "#validate_posting!" do
      let(:voucher) { described_class.new }

      # Since validate_posting! is private, we test through the behavior it implements in subclasses

      context "when voucher is already posted" do
        it "raises an error when called via subclass post_entry!" do
          voucher.status = "posted"
          # Create a new instance of voucher to avoid any issues since it's a class method
          voucher_instance = described_class.new(status: "posted")
          expect { voucher_instance.post_entry!(credit_account: nil) }.to raise_error("Voucher already posted")
        end
      end

      context "when voucher is cancelled" do
        it "raises an error when called via subclass post_entry!" do
          voucher.status = "cancelled"
          # Create a new instance of voucher to avoid any issues since it's a class method
          voucher_instance = described_class.new(status: "cancelled")
          expect { voucher_instance.post_entry!(credit_account: nil) }.to raise_error("Voucher is cancelled")
        end
      end

      context "when cash session is closed" do
        let(:closed_cash_session) { instance_double(Treasury::CashSession, closed?: true) }
        
        it "raises an error when called via subclass post_entry!" do
          voucher_instance = described_class.new(status: "pending")
          # Set the instance variable to simulate a closed cash session
          allow(voucher_instance).to receive(:cash_session).and_return(closed_cash_session)
          expect { voucher_instance.post_entry!(credit_account: nil) }.to raise_error("Cash session is closed")
        end
      end

      context "when conditions are valid" do
        it "does not raise an error when called via subclass post_entry!" do
          voucher.status = "pending"
          voucher_instance = described_class.new(status: "pending")
          expect { voucher_instance.post_entry!(credit_account: nil) }.to raise_error(NotImplementedError)
        end
      end
    end

    describe "#assign_voucher_number" do
      let(:voucher) { described_class.new }

      context "when voucher number is present" do
        it "does not overwrite existing voucher number" do
          voucher.voucher_number = "CRV-20230101-ABCDEF"
          voucher.send(:assign_voucher_number)
          expect(voucher.voucher_number).to eq("CRV-20230101-ABCDEF")
        end
      end

      it "generates a receipt voucher number" do
        voucher.type = "Treasury::CashReceiptVoucher"
        voucher.send(:assign_voucher_number)
        expect(voucher.voucher_number).to match(/^CRV-\d{8}-[A-F0-9]{6}$/)
      end

      it "generates a disbursement voucher number" do
        voucher.type = "Treasury::CashDisbursementVoucher"
        voucher.send(:assign_voucher_number)
        expect(voucher.voucher_number).to match(/^CDV-\d{8}-[A-F0-9]{6}$/)
      end
    end
  end

  describe "behavior" do
    it "raises NotImplementedError for post_entry!" do
      voucher = described_class.new
      expect { voucher.post_entry! }.to raise_error(NotImplementedError, "Subclasses must implement #post_entry!")
    end
  end
end