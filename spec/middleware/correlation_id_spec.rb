require "rails_helper"

RSpec.describe CorrelationId do
  let(:app) { ->(env) { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] } }
  let(:middleware) { described_class.new(app) }

  it "sets a correlation ID from X-Request-Id header" do
    env = Rack::MockRequest.env_for("/", "HTTP_X_REQUEST_ID" => "abc-123")
    _, headers, = middleware.call(env)
    expect(headers["X-Request-Id"]).to eq("abc-123")
  end

  it "generates a UUID when no X-Request-Id header exists" do
    env = Rack::MockRequest.env_for("/")
    _, headers, = middleware.call(env)
    expect(headers["X-Request-Id"]).to match(/\A[0-9a-f-]{36}\z/)
  end

  it "sets Current.request_id during the request" do
    env = Rack::MockRequest.env_for("/", "HTTP_X_REQUEST_ID" => "req-1")
    captured = nil
    app = ->(env2) { captured = Current.request_id; [ 200, {}, [] ] }
    middleware = described_class.new(app)

    middleware.call(env)
    expect(captured).to eq("req-1")
  end

  it "resets Current after the request" do
    env = Rack::MockRequest.env_for("/", "HTTP_X_REQUEST_ID" => "req-1")
    middleware.call(env)
    expect(Current.request_id).to be_nil
  end
end
