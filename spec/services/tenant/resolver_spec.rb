require "rails_helper"

RSpec.describe Tenant::Resolver, type: :service do
  describe "#resolve" do
    context "via subdomain" do
      it "finds cooperative by subdomain" do
        cooperative = create(:cooperative, subdomain: "test-coop")
        request = instance_double(ActionDispatch::Request, host: "test-coop.example.com")

        resolver = described_class.new(request: request)
        expect(resolver.resolve).to eq(cooperative)
      end

      it "returns nil for unknown subdomain" do
        request = instance_double(ActionDispatch::Request, host: "unknown.example.com")

        resolver = described_class.new(request: request)
        expect(resolver.resolve).to be_nil
      end

      it "returns nil for www subdomain" do
        request = instance_double(ActionDispatch::Request, host: "www.example.com")

        resolver = described_class.new(request: request)
        expect(resolver.resolve).to be_nil
      end

      it "returns nil for root domain" do
        request = instance_double(ActionDispatch::Request, host: "example.com")

        resolver = described_class.new(request: request)
        expect(resolver.resolve).to be_nil
      end
    end

    context "via user context" do
      it "finds cooperative by user" do
        cooperative = create(:cooperative)
        user = create(:user, cooperative: cooperative)

        resolver = described_class.new(user: user)
        expect(resolver.resolve).to eq(cooperative)
      end
    end

    context "resolution priority" do
      it "prefers subdomain over user context" do
        subdomain_coop = create(:cooperative, subdomain: "alpha")
        user_coop = create(:cooperative, subdomain: "beta")
        user = create(:user, cooperative: user_coop)
        request = instance_double(ActionDispatch::Request, host: "alpha.example.com")

        resolver = described_class.new(request: request, user: user)
        expect(resolver.resolve).to eq(subdomain_coop)
      end
    end
  end

  describe "#resolve!" do
    it "raises when no tenant is resolved" do
      resolver = described_class.new
      expect { resolver.resolve! }.to raise_error(Tenant::Resolver::TenantNotResolvedError)
    end
  end
end
