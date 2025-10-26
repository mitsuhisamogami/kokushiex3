# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScorePolicy do
  subject(:policy) { described_class.new(user, score) }

  let(:test) { create(:test) }
  let(:examination) { create(:examination, user: examination_owner, test:) }
  let(:score) { create(:score, examination:) }

  context '所有者の場合' do
    let(:examination_owner) { create(:user) }
    let(:user) { examination_owner }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context '他のユーザーの場合' do
    let(:examination_owner) { create(:user) }
    let(:user) { create(:user) }

    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:examination_owner) { user }
    let(:other_examination) { create(:examination, user: other_user, test:) }

    before do
      create(:score, examination:)
      create(:score, examination: other_examination)
    end

    it '自分のscoresのみを返す' do
      scope = described_class::Scope.new(user, Score.all).resolve
      expect(scope).to all(have_attributes(examination: have_attributes(user:)))
      expect(scope.count).to eq(1)
    end
  end
end
