FactoryBot.define do
  factory :accounting_entry_template, class: "Accounting::EntryTemplate" do
    name { "Interest Earned" }
    description { "Standard interest earned entry" }
    is_active { true }

    after(:build) do |template|
      debit_account = Accounting::Account.find_by(name: "Cash on Hand") || build(:accounting_account, name: "Cash on Hand")
      credit_account = Accounting::Account.find_by(name: "Interest Income") || build(:accounting_account, name: "Interest Income")

      template.lines << build(:accounting_entry_template_line,
        entry_template: template,
        account: debit_account,
        direction: "debit",
        amount_mode: "variable",
        sequence_index: 1
      ) unless template.lines.any? { |l| l.direction == "debit" }

      template.lines << build(:accounting_entry_template_line,
        entry_template: template,
        account: credit_account,
        direction: "credit",
        amount_mode: "variable",
        sequence_index: 2
      ) unless template.lines.any? { |l| l.direction == "credit" }
    end
  end

  factory :accounting_entry_template_line, class: "Accounting::EntryTemplateLine" do
    entry_template { nil }
    association :account, factory: :accounting_account
    direction { "debit" }
    amount_mode { "variable" }
    sequence_index { 1 }
  end
end
