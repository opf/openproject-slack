require 'spec_helper'

RSpec.describe OpenProject::Slack::Notifier do
  describe '#say' do
    let(:url) { 'https://hooks.slack.com/services/foo' }
    let(:message) { 'message' }
    let(:dummy) do
      Object.new.tap do |d|
        def d.post(*args)
        end
      end
    end

    let(:webhook_url) { 'https://hooks.slack.com/services/bar' }

    it 'should use the override URL' do
      expect(::Slack::Notifier).to receive(:new).with(webhook_url).and_return(dummy)
      expect(dummy).to receive(:post).with({ text: message, link_names: 1 })

      OpenProject::Slack::Notifier.say text: message, webhook_url: webhook_url

      perform_enqueued_jobs
    end
  end
end
