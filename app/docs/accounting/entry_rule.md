Journal Posting + Template System (Coop Core Banking)
1. Overview

This module defines a strict, deterministic accounting engine where users never directly interact with accounts during posting.

Instead, users operate on:

Business Intent → Journal Entry Template → System-resolved Ledger Posting

The system ensures all journal entries are:

Balanced
Auditable
Deterministically generated
Template-driven only
2. Core Design Principle (Hard Rule)

❌ Users MUST NOT select accounts
✅ All accounts are resolved via templates + posting engine

Any violation is a design failure, not a UI choice.

3. Domain Scope
3.1 Core Domains
Accounting
JournalEntry
EntryLine
EntryTemplate
EntryTemplateLine
Posting Engine
Template Resolution System
Audit & Traceability
4. User Flow (End-to-End)
4.1 Posting Flow
User selects EntryTemplate
User inputs:
amount
reference (optional)
metadata (member, loan, etc.)
System generates Preview Journal Entry
User confirms
System posts entry atomically
5. Models (Rails 8)
5.1 JournalEntry

Represents a finalized accounting entry.

class JournalEntry < ApplicationRecord
  has_many :entry_lines, dependent: :destroy

  belongs_to :entry_template, optional: true

  enum status: {
    draft: 0,
    posted: 1,
    reversed: 2
  }

  validates :total_debit, :total_credit, presence: true
end
Fields
Field	Type	Description
id	uuid	primary key
entry_number	string	unique reference
entry_template_id	uuid	source template
status	integer	draft/posted/reversed
total_debit	decimal	computed
total_credit	decimal	computed
metadata	jsonb	flexible context
posted_at	datetime	final posting time
5.2 EntryLine

Represents debit/credit lines.

class EntryLine < ApplicationRecord
  belongs_to :journal_entry
  belongs_to :account
end
Fields
Field	Type	Description
id	uuid	primary key
journal_entry_id	uuid	parent entry
account_id	uuid	resolved system account
direction	string	debit/credit
amount	decimal	line amount
description	string	optional
5.3 EntryTemplate

Defines a reusable accounting pattern.

class EntryTemplate < ApplicationRecord
  has_many :entry_template_lines, dependent: :destroy
end
Fields
Field	Type	Description
id	uuid	primary key
name	string	e.g. Loan Disbursement
code	string	unique
domain	string	lending/savings/etc
active	boolean	enable/disable
input_schema	jsonb	required user inputs
description	text	business meaning
5.4 EntryTemplateLine

Defines how journal entries are constructed.

class EntryTemplateLine < ApplicationRecord
  belongs_to :entry_template
end
Fields
Field	Type	Description
id	uuid	primary key
entry_template_id	uuid	parent template
account_id	uuid	fixed system account
direction	string	debit/credit
amount_mode	string	fixed
amount_value	decimal	optional fixed value
formula	string	optional expression
sort_order	integer	ordering
5.5 Account

Core ledger account.

class Account < ApplicationRecord
  has_many :entry_lines
end
Fields
Field	Type
id	uuid
name	string
code	string
account_type	string
normal_balance	string (debit/credit)
is_system	boolean
6. Services Layer (Core Engine)
6.1 PostingEngine

Central brain of journal posting system

class PostingEngine
  def initialize(template:, input:, actor:)
    @template = template
    @input = input
    @actor = actor
  end

  def preview
    build_entry(draft: true)
  end

  def post!
    ActiveRecord::Base.transaction do
      entry = build_entry(draft: false)
      entry.save!
      entry.update!(status: :posted, posted_at: Time.current)
      entry
    end
  end

  private

  def build_entry(draft:)
    JournalEntry.new(
      entry_template: @template,
      status: draft ? :draft : :posted,
      metadata: @input
    ).tap do |entry|
      lines = TemplateResolver.new(@template, @input).resolve_lines
      entry.entry_lines = lines
      entry.total_debit = sum(lines, "debit")
      entry.total_credit = sum(lines, "credit")
    end
  end
end
6.2 TemplateResolver

Converts template → concrete journal lines

class TemplateResolver
  def initialize(template, input)
    @template = template
    @input = input
  end

  def resolve_lines
    @template.entry_template_lines.map do |line|
      EntryLine.new(
        account_id: line.account_id,
        direction: line.direction,
        amount: resolve_amount(line),
        description: line.description
      )
    end
  end

  private

  def resolve_amount(line)
    case line.amount_mode
    when "fixed"
      line.amount_value
    when "variable"
      @input["amount"]
    when "formula"
      evaluate_formula(line.formula)
    end
  end
end
6.3 ValidationEngine

Ensures accounting correctness.

Rules:

Entry MUST be balanced
No missing accounts
No zero entries
No negative inconsistencies
class ValidationEngine
  def self.validate!(entry)
    raise "Unbalanced entry" unless balanced?(entry)
    raise "Invalid lines" if entry.entry_lines.empty?
  end
end
7. Database Schema (Rails Migrations)
7.1 accounts
create_table :accounts, id: :uuid do |t|
  t.string :name
  t.string :code
  t.string :account_type
  t.string :normal_balance
  t.boolean :is_system, default: false
  t.timestamps
end
7.2 journal_entries
create_table :journal_entries, id: :uuid do |t|
  t.string :entry_number
  t.references :entry_template, type: :uuid
  t.integer :status, default: 0
  t.decimal :total_debit, precision: 18, scale: 2
  t.decimal :total_credit, precision: 18, scale: 2
  t.jsonb :metadata
  t.datetime :posted_at
  t.timestamps
end
7.3 entry_lines
create_table :entry_lines, id: :uuid do |t|
  t.references :journal_entry, type: :uuid
  t.references :account, type: :uuid
  t.string :direction
  t.decimal :amount, precision: 18, scale: 2
  t.string :description
  t.timestamps
end
7.4 entry_templates
create_table :entry_templates, id: :uuid do |t|
  t.string :name
  t.string :code
  t.string :domain
  t.jsonb :input_schema
  t.text :description
  t.boolean :active, default: true
  t.timestamps
end
7.5 entry_template_lines
create_table :entry_template_lines, id: :uuid do |t|
  t.references :entry_template, type: :uuid
  t.references :account, type: :uuid
  t.string :direction
  t.string :amount_mode
  t.decimal :amount_value, precision: 18, scale: 2
  t.string :formula
  t.integer :sort_order
  t.timestamps
end
8. API Design (Opencode-ready)
8.1 Preview Entry
POST /accounting/journal_entries/preview
{
  "template_id": "uuid",
  "input": {
    "amount": 10000,
    "member_id": "123"
  }
}
8.2 Post Entry
POST /accounting/journal_entries

Same payload → final commit

8.3 List Templates
GET /accounting/entry_templates
9. UI Rules (Critical)
No account dropdowns anywhere
Only templates selectable
Preview screen is mandatory
Posting requires confirmation step
Journal lines are read-only in UI
10. Audit Requirements

Every journal entry MUST store:

template used
input payload
resolved accounts
timestamp
actor (user)
11. Extensions (Future-Proofing)
Multi-branch posting rules
Currency support
Reversal engine
Approval workflows
AI-assisted template suggestion
12. System Guarantees

This system guarantees:

100% deterministic accounting output
No manual ledger manipulation
Full audit traceability
Template-based financial logic enforcement