# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::Slack
  class Engine < ::Rails::Engine
    engine_name :openproject_slack

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-slack',
             author_url: 'https://openproject.org',
             requires_openproject: '>= 9.0.0',
             settings: {
               default: {
                 webhook_url: ''
               },
               partial: 'settings/slack'
             }

    initializer 'slack.register_hooks' do
      require 'open_project/slack/hook_listener'
    end
  end
end
