module Messaging
  module Providers
    class SesProvider < BaseProvider
      def perform_send
        require "aws-sdk-ses"

        aws_config = {
          region: config[:region] || ENV["AWS_REGION"] || "us-east-1",
          access_key_id: config[:access_key_id] || ENV["AWS_ACCESS_KEY_ID"],
          secret_access_key: config[:secret_access_key] || ENV["AWS_SECRET_ACCESS_KEY"]
        }

        client = Aws::SES::Client.new(aws_config)

        to_email = extract_recipient_email
        from_email = config[:from_email] || ENV["SES_FROM_EMAIL"]

        response = client.send_email(
          source: from_email,
          destination: { to_addresses: [ to_email ] },
          message: {
            subject: { data: subject },
            body: { html: { data: html_body } }
          }
        )

        Result.success(response.message_id)
      end

      private

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
