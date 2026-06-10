require "rails_helper"

RSpec.describe "Dashboard" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  it "renders the dashboard index" do
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "renders loans page" do
    get dashboard_loans_path
    expect(response).to have_http_status(:ok)
  end

  it "renders payments page" do
    get dashboard_payments_path
    expect(response).to have_http_status(:ok)
  end

  it "renders members page" do
    get dashboard_members_path
    expect(response).to have_http_status(:ok)
  end

  it "renders tasks page" do
    get dashboard_tasks_path
    expect(response).to have_http_status(:ok)
  end

  it "renders reports page" do
    get dashboard_reports_path
    expect(response).to have_http_status(:ok)
  end

  it "renders settings page" do
    get dashboard_settings_path
    expect(response).to have_http_status(:ok)
  end
end