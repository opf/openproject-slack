#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'slack-notifier'

class SlackNotificationJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(params:, webhook_url:)
    if webhook_url.blank?
      OpenProject.logger.warn "Slack webhook URL not defined"

      return
    end

    # prevent https://community.openproject.org/work_packages/56435/activity
    if !URI(webhook_url).respond_to?(:request_uri)
      OpenProject.logger.warn("Slack webhook URL is misconfigured: #{webhook_url}")

      return
    end

    notifier(webhook_url: webhook_url).post params
  rescue Slack::Notifier::APIError => e
    OpenProject.logger.warn "Error posting to Slack: #{e.message}"
  end

  def notifier(webhook_url: nil)
    ::Slack::Notifier.new webhook_url.presence || OpenProject::Slack.default_webhook_url
  end
end
