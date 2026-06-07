# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'development seed users' do
  def parse_seed_value(string:, boolean:, integer:)
    return boolean == 'true' if boolean
    return integer.to_i if integer

    string
  end

  def parse_seed_row(row)
    row.scan(/(\w+):\s*(?:'([^']*)'|(true|false)|(\d+))/).each_with_object({}) do |match, hash|
      key, string, boolean, integer = match
      hash[key.to_sym] = parse_seed_value(string:, boolean:, integer:)
    end
  end

  def development_user_seed_rows
    source = Rails.root.join('db/fixtures/development/01_user.rb').read
    source.scan(/\{[^{}]+\}/).map { |row| parse_seed_row(row) }
  end

  it '開発用fixtureに管理者ログイン確認用ユーザーが定義されている' do
    admin = development_user_seed_rows.find { |row| row[:email] == 'admin@example.com' }

    expect(admin).to include(
      email: 'admin@example.com',
      password: 'admin123',
      admin: true
    )
  end

  it 'production fixturesにUser.seedを含めない' do
    production_sources = Rails.root.glob('db/fixtures/production/**/*.rb').map(&:read)

    expect(production_sources).not_to include(a_string_matching(/User\.seed/))
  end
end
# rubocop:enable RSpec/DescribeClass
