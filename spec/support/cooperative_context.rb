RSpec.configure do |config|
  config.before(:each) do
    coop = create(:cooperative)
    Current.cooperative = coop
  end

  config.after(:each) do
    Current.reset
  end
end
