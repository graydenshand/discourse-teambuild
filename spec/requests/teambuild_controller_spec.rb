# frozen_string_literal: true

require "rails_helper"

describe DiscourseTeambuild::TeambuildController do

  it "returns 403 when anonymous" do
    SiteSetting.teambuild_enabled = true
    get "/team-build/about.json"
    expect(response.code).to eq("403")
  end

  context "logged in" do
    fab!(:user) { Fabricate(:user) }
    fab!(:target) do
      TeambuildTarget.create!(
        name: 'test target',
        target_type_id: TeambuildTarget.target_types[:regular]
      )
    end

    before do
      SiteSetting.teambuild_enabled = true
      sign_in(user)
    end

    context "enabled/disabled" do
      it "returns 403 when disabled" do
        SiteSetting.teambuild_enabled = false
        get "/team-build/about.json"
        expect(response.code).to eq("403")
      end

      it "returns 200 when enabled" do
        get "/team-build/about.json"
        expect(response.code).to eq("200")
      end
    end

    context "progress" do
      it "returns json" do
        put "/team-build/complete/#{target.id}/#{user.id}.json"

        get "/team-build/progress.json"
        json = JSON.parse(response.body)
        expect(json).to be_present

        progress = json['teambuild_progress']
        expect(progress['teambuild_target_ids']).to include(target.id)

        expect(progress['completed']).to include("#{target.id}:#{user.id}")

        targets = json['teambuild_targets']
        expect(targets).to be_present
        json_target = targets.find { |t| t['id'] == target.id }
        expect(json_target).to be_present
      end

      it "returns completed" do
        get "/team-build/progress.json"
        json = JSON.parse(response.body)
        expect(json).to be_present

        progress = json['teambuild_progress']
        expect(progress['teambuild_target_ids']).to include(target.id)

        targets = json['teambuild_targets']
        expect(targets).to be_present
        json_target = targets.find { |t| t['id'] == target.id }
        expect(json_target).to be_present
      end
    end

    context "complete / undo " do
      it "will mark the target as completed" do
        put "/team-build/complete/#{target.id}/#{user.id}.json"
        expect(response.code).to eq("200")
        expect(TeambuildTargetUser.find_by(user_id: user.id, teambuild_target_id: target.id)).to be_present

        # Test duplicate, should not error
        put "/team-build/complete/#{target.id}/#{user.id}.json"
        expect(response.code).to eq("200")

        delete "/team-build/undo/#{target.id}/#{user.id}.json"
        expect(response.code).to eq("200")
        expect(TeambuildTargetUser.find_by(user_id: user.id, teambuild_target_id: target.id)).to be_blank
      end
    end
  end

end
