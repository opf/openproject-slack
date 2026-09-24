require 'spec_helper'

RSpec.describe 'Admin slack plugin settings' do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
    Setting.plugin_openproject_slack = { 'enabled' => true, 'webhook_url' => 'https://hooks.slack.com/services/foo' }
  end

  it 'renders the Primer form and lets me update the webhook url' do
    visit '/admin/settings/plugin/openproject_slack'

    expect(page).to have_field('Default Webhook URL', with: 'https://hooks.slack.com/services/foo')
    expect(page).to have_link(OpenProject::Slack.webhook_url_label)
    expect(page).to have_text('custom field which can be set in the project settings')

    fill_in 'Default Webhook URL', with: 'https://hooks.slack.com/services/bar'
    click_button 'Apply'

    expect(page).to have_current_path('/admin/settings/plugin/openproject_slack')
    expect_flash(message: I18n.t(:notice_successful_update))
    expect(page).to have_field('Default Webhook URL', with: 'https://hooks.slack.com/services/bar')

    expect(Setting.plugin_openproject_slack['webhook_url']).to eq('https://hooks.slack.com/services/bar')
    expect(Setting.plugin_openproject_slack['enabled']).to eq('1')
  end
end
