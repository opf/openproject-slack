require 'slack-notifier'

module OpenProject::Slack::Notifier
  module_function

  def say(text:, attachments: nil, webhook_url: nil)
    params = default_params.dup.merge(text: text)
    params[:attachments] = Array(attachments) if attachments.present?

    notifier(webhook_url: webhook_url).post params
  end

  def notifier(webhook_url: nil)
    ::Slack::Notifier.new webhook_url.presence || OpenProject::Slack.default_webhook_url
  end

  def default_params
    @default_params ||= { link_names: 1 }.freeze
  end
end
