class SubdomainPresent
  def self.matches?(request)
    sub = request.subdomain
    sub.present? && sub != "www"
  end
end

class NoSubdomain
  def self.matches?(request)
    request.subdomain.blank? || request.subdomain == "www"
  end
end
