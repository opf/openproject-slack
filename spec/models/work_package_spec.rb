require 'spec_helper'
require 'slack-notifier'

describe WorkPackage, with_settings: { "host_name" => "test.openproject.com", "protocol" => "https" } do
  let(:user) { FactoryBot.create :admin, firstname: "Peter", lastname: "Putzig" }
  let(:project) { FactoryBot.create :project_with_types, name: "Parts", identifier: "parts" }

  let(:notifier) do
    Object.new.tap do |n|
      def n.post(*args)
      end
    end
  end

  describe 'update' do
    let(:work_package) { FactoryBot.create :work_package, project: project, subject: "Tires" }

    before do
      work_package # create work package before slack is enabled so we only test updates

      allow(::OpenProject::Slack).to receive(:default_webhook_url).and_return("https://foo.bar.com/webhook/42")
    end

    let(:update_service) { WorkPackages::UpdateService.new user: user, model: work_package }
    let(:expected_text) do
      "[<https://test.openproject.com/projects/#{project.identifier}|#{project.name}>] #{user.name} updated <https://test.openproject.com/work_packages/#{work_package.id}|#{work_package.type.name} ##{work_package.id}: #{work_package.subject}>"
    end

    before do
      expect(OpenProject::Slack::Notifier).to receive(:say) do |opts|
        expect(opts[:text]).to eq expected_text

        field = opts[:attachments].first[:fields].first

        expect(field[:title]).to eq "Description"
        expect(field[:value]).to eq work_package.description
      end
    end

    it "posts an update notification" do
      res = update_service.call description: "Tires should be round-ish"

      expect(res).to be_success
    end
  end

  describe 'create' do
    let(:status) { FactoryBot.create :status }
    let(:priority) { FactoryBot.create :priority }
    let(:type) { project.types.first }
    let(:subject) { "Tires" }
    let(:description) { "Tires should be round" }

    before do
      allow(::OpenProject::Slack).to receive(:default_webhook_url).and_return("https://foo.bar.com/webhook/42")
    end

    let(:create_service) { WorkPackages::CreateService.new user: user }

    before do
      expect(OpenProject::Slack::Notifier).to receive(:say) do |opts|
        expect(opts[:attachments].first[:text]).to eq description

        titles = opts[:attachments].first[:fields].map { |f| f[:title] }
        expect(titles).to eq ["Status", "Priority", "Assigned to", "Watcher"]

        text = opts[:text]

        expect(text).to start_with("[<https://test.openproject.com/projects/#{project.identifier}|#{project.name}>] #{user.name} created <https://test.openproject.com/work_packages/")
        expect(text).to match /.*\/work_packages\/\d+\|#{type.name} #\d+: #{subject}>$/
      end
    end

    it "posts a create notification" do
      res = create_service.call(
        subject: subject,
        description: description,
        project_id: project.id,
        status_id: status.id,
        type_id: type.id,
        priority_id: priority.id
      )

      expect(res).to be_success
    end
  end
end
