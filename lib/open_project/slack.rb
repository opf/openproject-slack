module OpenProject
  module Slack
    require "open_project/slack/engine"

    class << self
      def webhook_url_label
        "Slack Webhook URL"
      end

      def default_webhook_url
        Setting.plugin_openproject_slack["webhook_url"]
      end

      def configured?
        default_webhook_url.present?
      end

      def project_custom_field_params
        {
          name: webhook_url_label,
          type: 'ProjectCustomField',
          field_format: 'string'
        }
      end

      def project_custom_field
        CustomField.find_or_create_by project_custom_field_params
      end
    end
  end
end
