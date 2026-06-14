# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Oauth::AuthHashReader do
  subject(:reader) { described_class.new(auth) }

  def auth_hash(provider: 'line', uid: 'line-uid-123', info: {}, raw_info: {})
    OmniAuth::AuthHash.new(
      provider:,
      uid:,
      info:,
      extra: { raw_info: }
    )
  end

  def line_auth_hash(info: {}, raw_info: nil, id_info: nil)
    extra = {}
    extra[:raw_info] = raw_info if raw_info
    extra[:id_info] = id_info if id_info

    OmniAuth::AuthHash.new(
      provider: 'line',
      uid: 'line-uid-123',
      info:,
      extra:
    )
  end

  describe '#email' do
    it 'info.emailを正規化して返す' do
      auth = auth_hash(info: { email: ' LINE_USER@EXAMPLE.COM ' })

      expect(described_class.new(auth).email).to eq 'line_user@example.com'
    end

    it 'info.emailがない場合はraw_info.emailを読む' do
      auth = auth_hash(info: {}, raw_info: { email: 'line-user@example.com' })

      expect(described_class.new(auth).email).to eq 'line-user@example.com'
    end

    it 'LINEでraw_infoがない場合はid_info.emailを読む' do
      auth = line_auth_hash(info: {}, id_info: { email: 'line-user@example.com' })

      expect(described_class.new(auth).email).to eq 'line-user@example.com'
    end
  end

  describe '#name' do
    it 'info.nameを返す' do
      auth = auth_hash(info: { name: 'Info Name' }, raw_info: { name: 'Raw Name' })

      expect(described_class.new(auth).name).to eq 'Info Name'
    end

    it 'info.nameがない場合はraw_info.nameを返す' do
      auth = auth_hash(info: {}, raw_info: { name: 'Raw Name' })

      expect(described_class.new(auth).name).to eq 'Raw Name'
    end

    it 'LINEでraw_infoがない場合はid_info.nameを返す' do
      auth = line_auth_hash(info: {}, id_info: { name: 'ID Name' })

      expect(described_class.new(auth).name).to eq 'ID Name'
    end
  end

  describe '#image_url' do
    it 'info.imageを返す' do
      auth = auth_hash(info: { image: 'https://example.com/info.png' },
                       raw_info: { picture: 'https://example.com/raw.png' })

      expect(described_class.new(auth).image_url).to eq 'https://example.com/info.png'
    end

    it 'info.imageがない場合はraw_info.pictureを返す' do
      auth = auth_hash(info: {}, raw_info: { picture: 'https://example.com/raw.png' })

      expect(described_class.new(auth).image_url).to eq 'https://example.com/raw.png'
    end

    it 'LINEでraw_infoがない場合はid_info.pictureを返す' do
      auth = line_auth_hash(info: {}, id_info: { picture: 'https://example.com/id.png' })

      expect(described_class.new(auth).image_url).to eq 'https://example.com/id.png'
    end
  end

  describe '#verified_email?' do
    context 'Googleの場合' do
      it 'raw_info.email_verifiedがboolean trueでemailが一致する場合のみtrueを返す' do
        auth = auth_hash(
          provider: 'google_oauth2',
          info: { email: 'google-user@example.com', email_verified: true },
          raw_info: { email: 'google-user@example.com', email_verified: true }
        )

        expect(described_class.new(auth)).to be_verified_email
      end

      it 'info.email_verifiedがtrueでもraw_info.email_verifiedがtrueでなければfalseを返す' do
        auth = auth_hash(
          provider: 'google_oauth2',
          info: { email: 'google-user@example.com', email_verified: true },
          raw_info: { email: 'google-user@example.com', email_verified: 'true' }
        )

        expect(described_class.new(auth)).not_to be_verified_email
      end
    end

    context 'LINEの場合' do
      it 'id_info.emailが取得emailと一致する場合にtrueを返す' do
        auth = line_auth_hash(
          info: { email: 'line-user@example.com' },
          id_info: { email: 'line-user@example.com', name: 'LINE User' }
        )

        expect(described_class.new(auth)).to be_verified_email
      end

      it 'raw_info.email_verifiedがboolean trueでemailが一致する場合にtrueを返す' do
        auth = auth_hash(
          info: { email: 'line-user@example.com' },
          raw_info: { email: 'line-user@example.com', email_verified: true }
        )

        expect(described_class.new(auth)).to be_verified_email
      end

      it 'raw_info.verified_emailがboolean trueでemailが一致する場合にtrueを返す' do
        auth = auth_hash(
          info: { email: 'line-user@example.com' },
          raw_info: { email: 'line-user@example.com', verified_email: true }
        )

        expect(described_class.new(auth)).to be_verified_email
      end

      it 'raw_infoがない場合はid_info.email一致でtrueを返す' do
        auth = line_auth_hash(
          info: { email: 'line-user@example.com' },
          id_info: { email: 'line-user@example.com' }
        )

        expect(described_class.new(auth)).to be_verified_email
      end

      it 'emailが存在するだけではtrueを返さない' do
        auth = auth_hash(
          info: { email: 'line-user@example.com' },
          raw_info: { email: 'line-user@example.com' }
        )

        expect(described_class.new(auth)).not_to be_verified_email
      end

      it 'verified claimがfalseの場合はfalseを返す' do
        auth = auth_hash(
          info: { email: 'line-user@example.com' },
          raw_info: { email: 'line-user@example.com', email_verified: false, verified_email: false }
        )

        expect(described_class.new(auth)).not_to be_verified_email
      end

      it 'verified claimが文字列trueの場合はfalseを返す' do
        auth = auth_hash(
          info: { email: 'line-user@example.com' },
          raw_info: { email: 'line-user@example.com', email_verified: 'true' }
        )

        expect(described_class.new(auth)).not_to be_verified_email
      end

      it 'raw_info.emailと取得emailが一致しない場合はfalseを返す' do
        auth = auth_hash(
          info: { email: 'line-user@example.com' },
          raw_info: { email: 'other@example.com', email_verified: true }
        )

        expect(described_class.new(auth)).not_to be_verified_email
      end

      it 'id_info.emailと取得emailが一致しない場合はfalseを返す' do
        auth = line_auth_hash(
          info: { email: 'line-user@example.com' },
          id_info: { email: 'other@example.com' }
        )

        expect(described_class.new(auth)).not_to be_verified_email
      end
    end
  end
end
