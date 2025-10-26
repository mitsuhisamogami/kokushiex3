# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExaminationPolicy do
  subject(:policy) { described_class.new(user, examination) }

  let(:test) { create(:test) }
  let(:examination) { create(:examination, user: examination_owner, test:) }

  context '所有者の場合' do
    let(:examination_owner) { create(:user) }
    let(:user) { examination_owner }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:edit) }
  end

  context '他のユーザーの場合' do
    let(:examination_owner) { create(:user) }
    let(:user) { create(:user) }

    it { is_expected.to forbid_action(:show) }
    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:edit) }
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:examination_owner) { user }

    before do
      create(:examination, user:, test:)
      create(:examination, user: other_user, test:)
    end

    it '自分のexaminationsのみを返す' do
      scope = described_class::Scope.new(user, Examination.all).resolve
      expect(scope).to all(have_attributes(user:))
      expect(scope.count).to eq(1)
    end
  end
end
