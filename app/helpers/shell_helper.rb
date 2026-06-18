module ShellHelper
  def cash_session_status_badge(cash_session)
    return nil unless cash_session
    return "OPEN" if cash_session.open?
    return "BALANCING" if cash_session.respond_to?(:balancing?) && cash_session.balancing?
    "CLOSED"
  end
end
