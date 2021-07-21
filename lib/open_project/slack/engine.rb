# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::Slack
  class Engine < ::Rails::Engine
    engine_name :openproject_slack

    include OpenProject::Plugins::ActsAsOpEngine

    register(
      'openproject-slack',
      author_url: 'https://www.openproject.org',
      requires_openproject: '>= 10.0.0',
      settings: {
        default: {
          "enabled" => true,
          "webhook_url" => ''
        },
        partial: 'settings/slack',
        menu_item: :slack_settings
      }
    ) do
      menu :admin_menu,
           :slack_settings,
           { controller: '/admin/settings', action: :show_plugin, id: :openproject_slack },
           caption: :label_slack_plugin,
           icon: 'icon2 icon-slack',
           if: ->(*) { User.current.admin? && ::OpenProject::Slack.enabled? }
    end

    initializer 'slack.register_hooks' do
      require 'open_project/slack/hook_listener'
    end
  end
end
