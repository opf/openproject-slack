# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/slack/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-slack"
  s.version     = OpenProject::Slack::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.homepage    = "https://community.openproject.org/projects/slack"  # TODO check this URL
  s.summary     = 'OpenProject Slack'
  s.description = "Slack integration"
  s.license     = "FIXME" # e.g. "MIT" or "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "rails", "~> 5.0"
  s.add_dependency "slack-notifier", "~> 2.3", ">= 2.3.2"
end
