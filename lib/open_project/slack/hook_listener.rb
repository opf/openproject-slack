require 'open_project/slack/notifier'

class OpenProject::Slack::HookListener < OpenProject::Hook::Listener
  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end

  def controller_wiki_edit_after_save(context = { })
    project = context[:project]
    webhook_url = project_webhook_url project

    return unless webhook_url.present?

    page = context[:page]
    user = page.content.author
    project_url = "<#{object_url project}|#{escape project}>"
    page_url = "<#{object_url page}|#{page.title}>"
    message = "[#{project_url}] #{page_url} updated by *#{user}*"
    attachment = nil

    if page.content.comments.present?
      attachment = {}
      attachment[:text] = "#{escape page.content.comments}"
    end

    OpenProject::Slack::Notifier.say(
      text: message,
      attachments: [attachment].compact,
      webhook_url: webhook_url
    )
  end

  def work_package_after_create(context={})
    work_package = context[:work_package]
    webhook_url = project_webhook_url work_package.project

    return unless webhook_url.present?

    work_package = context[:work_package]

    message = "[<#{object_url work_package.project}|#{escape work_package.project}>] #{escape work_package.author} created <#{object_url work_package}|#{escape work_package.to_s}>#{mentions work_package.description}"

    attachment = {}
    attachment[:text] = escape(work_package.description) if work_package.description.present?
    attachment[:fields] = [{
      title: I18n.t("field_status"),
      value: escape(work_package.status.to_s),
      short: true
    }, {
      title: I18n.t("field_priority"),
      value: escape(work_package.priority.to_s),
      short: true
    }, {
      title: I18n.t("field_assigned_to"),
      value: escape(work_package.assigned_to.to_s),
      short: true
    }]

    attachment[:fields] << {
      title: I18n.t("field_watcher"),
      value: escape(work_package.watcher_users.join(', ')),
      short: true
    }

    OpenProject::Slack::Notifier.say text: message, attachments: [attachment], webhook_url: webhook_url
  end

  def work_package_after_update(context={})
    work_package = context[:work_package]
    webhook_url = project_webhook_url work_package.project

    return unless webhook_url.present?

    journal = work_package.last_journal

    message = "[<#{object_url work_package.project}|#{escape work_package.project}>] #{escape journal.user.to_s} updated <#{object_url work_package}|#{escape work_package}>#{mentions journal.notes}"

    attachment = {}
    attachment[:text] = escape(journal.notes) if journal.notes.present?

    attachment[:fields] = journal.details.map do |key, changeset|
      detail_to_hash(work_package, key, changeset)
    end

    OpenProject::Slack::Notifier.say(
      text: message,
      attachments: [attachment],
      webhook_url: webhook_url
    )
  end

  private

  def escape(message)
    ERB::Util.html_escape message
  end

  def project_webhook_url(project)
    url = project.custom_values
      .joins(:custom_field)
      .where(custom_fields: { name: OpenProject::Slack::webhook_url_label })
      .pluck(:value)
      .first

    url ||= project_webhook_url(project.parent) if project.parent.present?
    url ||= OpenProject::Slack.default_webhook_url

    url
  end

  def default_url_options(repository, changeset)
    {
      controller: 'repositories',
      action: 'revision',
      id: repository.project,
      repository_id: repository.identifier_param,
      rev: changeset.revision,
      protocol: Setting.protocol
    }
  end

  def object_url(obj)
    if obj.is_a? Project
      url_helpers.project_url obj
    elsif obj.is_a? WorkPackage
      url_helpers.work_package_url obj
    else
      url_helpers.url_for obj.event_url
    end
  end

  def mentions(text)
    return nil if text.blank?

    names = extract_usernames text
    names.present? ? "\nTo: " + names.join(', ') : nil
  end

  def extract_usernames(text = '')
    # slack usernames may only contain lowercase letters, numbers,
    # dashes and underscores and must start with a letter or number.
    text.scan(/@[a-z0-9][a-z0-9_\-]*/).uniq
  end

  def detail_to_hash(work_package, key, changeset)
    method_name = if key =~ /_id$/
                    key.sub(/_id$/, '')
                  elsif key =~ /attachments_\d+/
                    key.sub(/_\d+/, '')
                  else
                    key
                  end
    title_key = "field_#{method_name}"

    hash = {
      title: I18n.t(title_key),
      short: true
    }

    value = if key =~ /_id$/
      escape(work_package.send(method_name)) if work_package.respond_to?(method_name)
    end

    value ||= escape(changeset.last)
    value = I18n.t('none') if value.blank?

    hash[:value] = value

    hash
  end
end
