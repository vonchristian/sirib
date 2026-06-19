module Messaging
  module Providers
    class SendgridProvider < BaseProvider
      def perform_send
        api_key = config[:api_key] || ENV["SENDGRID_API_KEY"]
        raise "Sendgrid API key not configured" unless api_key

        from_email = config[:from_email] || ENV["SENDGRID_FROM_EMAIL"]
        to_email = extract_recipient_email

        response = send_email(api_key, from_email, to_email, subject, html_body)

        Result.success(response.dig(:headers, :"x-message-id"))
      end

      private

      def send_email(api_key, from, to, subject, html_body)
        uri = URI("https://api.sendgrid.com/v3/mail/send")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{api_key}"
        request["Content-Type"] = "application/json"
        request.body = {
          personalizations: [ { to: [ { email: to } ] } ],
          from: { email: from },
          subject: subject,
          content: [ { type: "text/html", value: html_body } ]
        }.to_json

        http.request(request)
      end

      def extract_recipient_email
        recipient.email_address || payload[:email]
      end

      def subject
        payload[:subject] || default_subject
      end

      def html_body
        payload[:html_body] || payload[:body] || default_body
      end

      def default_subject
        case message.message_type
        when "member_activation" then "Activate Your Account"
        when "password_reset" then "Reset Your Password"
        when "block_notice" then "Important: Account Notice"
        else "Message from Sirib"
        end
      end

      def default_body
        payload[:token] ? "#{payload[:token]}" : "Please check your account for important information."
      end
    end
  end
end
