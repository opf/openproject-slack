namespace :slack do
  desc "Send message to slack."
  task :say => :environment do
    OpenProject::Slack::Notifier.say(
      webhook_url: ENV['HOOK'].presence,
      attachments: [ENV["ATTACHMENT"].presence].compact
    )
  end
end
