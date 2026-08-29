module Notifications
  module Domain
    # Wraps the Web Push protocol so callers deal in a subscription and a
    # message. An instance with no VAPID keys is the normal case for a
    # self-hoster who never set them up, so that reads as "off", not an error.
    class WebPushDelivery
      def self.configured?
        public_key.present? && private_key.present?
      end

      def self.public_key = ENV["VAPID_PUBLIC_KEY"].presence

      def self.private_key = ENV["VAPID_PRIVATE_KEY"].presence

      def self.subject = ENV.fetch("VAPID_SUBJECT", "mailto:stockerly@localhost")

      def self.call(subscription:, title:, body:, path:, badge_count:)
        return false unless configured?

        WebPush.payload_send(
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh_key,
          auth: subscription.auth_key,
          message: { title: title, body: body, path: path, badge: badge_count }.to_json,
          vapid: { subject: subject, public_key: public_key, private_key: private_key }
        )
        subscription.update_column(:last_delivered_at, Time.current)
        true
      rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
        # The browser dropped this install. Keeping the row would retry forever.
        subscription.destroy
        false
      rescue WebPush::ResponseError => e
        Rails.logger.warn("[web_push] #{subscription.id} rejected: #{e.message}")
        false
      end
    end
  end
end
