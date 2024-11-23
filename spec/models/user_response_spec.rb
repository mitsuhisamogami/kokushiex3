# == Schema Information
#
# Table name: user_responses
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  choice_id      :bigint           not null
#  examination_id :bigint           not null
#
# Indexes
#
#  index_user_responses_on_choice_id       (choice_id)
#  index_user_responses_on_examination_id  (examination_id)
#
# Foreign Keys
#
#  fk_rails_...  (choice_id => choices.id)
#  fk_rails_...  (examination_id => examinations.id)
#
require 'rails_helper'

RSpec.describe UserResponse do
  describe '#bulk_create_responses' do
    let(:examination) { create(:examination) }
    let(:choice_ids) { create_list(:choice, 3).map(&:id) }

    before do
      allow(Rails.logger).to receive(:error)
    end

    context '不正なchoice_idが含まれない場合' do
      it 'user_responsesが作成される' do
        expect do
          described_class.bulk_create_responses(examination, choice_ids)
        end.to change(described_class, :count).by(3)
      end

      it 'choice_id毎にuser_responseが作成される' do
        described_class.bulk_create_responses(examination, choice_ids)

        choice_ids.each do |choice_id|
          user_response = described_class.find_by(choice_id:)
          expect(user_response.examination_id).to eq(examination.id)
          expect(user_response.choice_id).to eq(choice_id)
        end
      end
    end

    context '無効なchoice_idが含まれる場合' do
      let(:invalid_choice_id) { 100 }

      it 'user_responseは1件も作成されない' do
        choice_ids_with_invalid = choice_ids + [invalid_choice_id]

        expect do
          described_class.bulk_create_responses(examination, choice_ids_with_invalid)
        end.not_to change(described_class, :count)
      end

      it 'logにerror messageが含まれる' do
        choice_ids_with_invalid = choice_ids + [invalid_choice_id]
        missing_ids = [invalid_choice_id]

        described_class.bulk_create_responses(examination.id, choice_ids_with_invalid)
        expect(Rails.logger).to have_received(:error).with("Missing Choice IDs: #{missing_ids.join(', ')}").once
      end
    end
  end
end
