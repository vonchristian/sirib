class Rack::Attack
  Rack::Attack.enabled = !Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("logins/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  throttle("password_resets/ip", limit: 5, period: 60) do |req|
    req.ip if req.path == "/passwords" && req.post?
  end

  throttle("mfa_challenge/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/mfa/verify" && req.post?
  end

  throttle("portal_logins/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/portal/session" && req.post?
  end

  throttle("api/ip", limit: 100, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  Rack::Attack.blocklist("block-bad-user-agents") do |req|
    bad_agents = /(nikto|scanify|masscan|dirbuster|sqlmap|nmap)/i
    req.user_agent if req.user_agent&.match?(bad_agents)
  end

  Rack::Attack.throttled_responder = lambda do |env|
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => env["rack.attack.match_data"]&.dig(:period).to_s
    }
    [ 429, headers, [ { error: "Rate limit exceeded. Try again later." }.to_json ] ]
  end
end
