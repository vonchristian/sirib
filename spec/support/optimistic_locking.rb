RSpec.shared_examples_for "an optimistically locked model" do
  let(:factory) { raise "define factory in example group" }
  let(:update_attrs) { raise "define update_attrs in example group" }

  it "raises StaleObjectError on concurrent save" do
    record = create(factory)
    e1 = record.class.find(record.id)
    e2 = record.class.find(record.id)

    e1.update!(update_attrs)

    expect { e2.update!(update_attrs) }
      .to raise_error(ActiveRecord::StaleObjectError)
  end

  it "increments lock_version on save" do
    record = create(factory)
    expect { record.update!(update_attrs) }
      .to change { record.reload.lock_version }.by(1)
  end
end
