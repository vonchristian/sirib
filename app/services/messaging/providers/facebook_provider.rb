module Messaging
  module Providers
    class FacebookProvider < BaseProvider
      def perform_send
        page_access_token = config[:page_access_token] || ENV["FACEBOOK_PAGE_ACCESS_TOKEN"]
        raise "Facebook page access token not configured" unless page_access_token

        recipient_id = extract_recipient_id
        raise "Recipient PSID not found" unless recipient_id

        response = send_message(page_access_token, recipient_id, message_payload)

        Result.success(response[:message_id])
      end

      private

      def send_message(token, recipient_id, message_payload)
        uri = URI("https://graph.facebook.com/v18.0/me/messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{token}"
        request["Content-Type"] = "application/json"
        request.body = {
          recipient: { id: recipient_id },
          message: message_payload
        }.to_json

        response = http.request(request)
        JSON.parse(response.body).with_indifferent_access
      end

      def extract_recipient_id
        payload[:psid] || recipient.facebook_psid
      end

      def message_payload
        if payload[:text]
          { text: payload[:text] }
        elsif payload[:attachment_url]
          {
            attachment: {
              type: "template",
              payload: {
                template_type: "button",
                text: payload[:button_text] || "View Details",
                buttons: [
                  {
                    type: "web_url",
                    url: payload[:attachment_url],
                    title: payload[:button_title] || "Open"
                  }
                ]
              }
            }
          }
        else
          { text: payload[:body] || "You have a new message." }
        end
      end
    end
  end
end
