require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'major question tag fixture' do
  let(:fixture_path) { Rails.root.join('db/fixtures/production/07_question_major_tag.rb') }

  def generated_question_tags
    records = nil
    relation = instance_double(ActiveRecord::Relation, delete_all: true)
    allow(QuestionTag).to receive(:where).with(question_id: 1..800, tag_id: [1, 2, 3]).and_return(relation)
    allow(QuestionTag).to receive(:seed) { |_key, rows| records = rows }

    load fixture_path
    records
  end

  it '既存分と第61回〜第59回に大分類タグを付与する' do
    records = generated_question_tags

    expect(records.size).to eq(960)
    expect(records.pluck(:question_id).uniq).to eq((1..800).to_a)
    expect(records.pluck(:id)).to eq((1..240).to_a + (441..1160).to_a)
  end

  it '既存fixtureに合わせて問題番号1〜20には専門と実地の両方を付与する' do
    records = generated_question_tags

    expect(records.count { |record| record[:tag_id] == 3 }).to eq(160)
    expect(records.count { |record| record[:tag_id] == 2 }).to eq(400)
    expect(records.count { |record| record[:tag_id] == 1 }).to eq(400)
  end

  it '細分類fixtureには大分類タグを含めない' do
    source = Rails.root.join('db/fixtures/production/08_question_tag.rb').read

    expect(source).not_to match(/tag_id: [123][, }]/)
  end
end
# rubocop:enable RSpec/DescribeClass
