#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WikiController, type: :controller do
  let(:protocol) { "https" }
  let(:host_name) { "test.openproject.com" }

  before do
    Role.delete_all # removing me makes us faster
    User.delete_all # removing me makes us faster
    I18n.locale = :en
  end

  describe 'actions', with_settings: { host_name: "test.openproject.com", protocol: "https" } do
    let(:page_title) { "abc" }

    let(:expected_text) do
      "[<#{protocol}://#{host_name}/projects/#{@project.identifier}|#{@project.name}>] " +
        "<#{protocol}://#{host_name}/projects/#{@project.identifier}/wiki/#{page_title}|#{page_title}> updated by *#{@user.name}*"
    end

    # copied from core wiki controller spec
    before do
      allow(@controller).to receive(:set_localization)

      @role = FactoryBot.create(:non_member)
      @user = FactoryBot.create(:admin)

      allow(User).to receive(:current).and_return @user

      @project = FactoryBot.create(:project)
      @project.reload # to get the wiki into the proxy

      # creating pages
      @existing_page = FactoryBot.create(
        :wiki_page, wiki_id: @project.wiki.id, title: 'ExistingPage'
      )

      # creating page contents
      FactoryBot.create(
        :wiki_content, page_id: @existing_page.id, author_id: @user.id
      )

      allow(::OpenProject::Slack).to receive(:default_webhook_url).and_return("https://foo.bar.com/webhook/42")

      expect(OpenProject::Slack::Notifier).to receive(:say) do |opts|
        expect(opts[:text]).to eq expected_text
      end
    end

    describe 'create' do
      it 'sends a slack notification' do
        post 'create',
             params: {
               project_id: @project,
               content: { text: 'h1. abc', page: { title: 'abc' } }
             }

        expect(response).to redirect_to action: 'show', project_id: @project, id: page_title
      end
    end

    describe 'update' do
      let(:page_title) { "ExistingPage" }

      it 'sends a slack notification' do
        post 'update',
             params: {
               id: page_title,
               project_id: @project,
               content: { text: 'h1. abc', page: { title: 'ExistingPage' } }
             }

        expect(response).to redirect_to action: 'show', project_id: @project, id: @existing_page.slug
      end
    end
  end
end
