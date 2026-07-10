class CorrelationId
  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = env["HTTP_X_REQUEST_ID"] || SecureRandom.uuid
    env["action_dispatch.request_id"] = request_id
    Current.request_id = request_id

    status, headers, body = @app.call(env)
    headers["X-Request-Id"] = request_id

    [ status, headers, body ]
  ensure
    Current.reset
  end
end
