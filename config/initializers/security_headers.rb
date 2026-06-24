class SecurityHeaders
  HEADERS = {
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "SAMEORIGIN",
    "X-XSS-Protection" => "0",
    "Referrer-Policy" => "strict-origin-when-cross-origin",
    "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=()",
    "Cross-Origin-Opener-Policy" => "same-origin",
    "Cross-Origin-Resource-Policy" => "same-origin"
  }.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    HEADERS.each do |name, value|
      headers[name] = value unless headers.key?(name)
    end

    [status, headers, body]
  end
end

Rails.application.config.middleware.use SecurityHeaders
