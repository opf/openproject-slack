module OpenProject
  module Slack
    require "open_project/slack/engine"

    class << self
      def webhook_url_label
        "Slack Webhook URL"
      end

      def default_webhook_url
        settings["webhook_url"]
      end

      def enable!
        set_enabled true
      end

      def disable!
        set_enabled false
      end

      def set_enabled(value)
        Setting.plugin_openproject_slack = settings.merge enabled: !!value
      end

      def enabled?
        !!settings["enabled"]
      end

      def disabled?
        !enabled?
      end

      def settings
        Setting.plugin_openproject_slack
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
