Rails.application.config.after_initialize do
  Grover.configure do |config|
    config.options = {
      format: "Letter",
      margin: { top: "0.5in", bottom: "0.5in", left: "0.75in", right: "0.75in" },
      print_background: true,
      prefer_css_page_size: true
    }
  end
end
