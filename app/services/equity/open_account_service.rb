module Equity
  class OpenAccountService < ActiveInteraction::Base
    object :member, class: Membership::Member
    object :share_product, class: Equity::Product
    integer :opened_by_id
    string :branch, default: nil
    string :remarks, default: nil

    def execute
      errors.add(:base, "Member already has an account for this product") if existing_account?

      account = Equity::Account.new(
        member: member,
        share_product: share_product,
        status: "active",
        opened_by_id: opened_by_id,
        branch: branch,
        remarks: remarks,
        shares_owned: 0,
        paid_up_shares: 0
      )

      unless account.save
        errors.merge!(account.errors)
        return
      end

      account
    end

    private

    def existing_account?
      Equity::Account.exists?(member_id: member.id, share_product_id: share_product.id, status: "active")
    end
  end
end
