# 大分類タグは問題番号ルールから生成する。
# 既存fixtureに合わせ、問題番号1〜20は専門問題と実地問題の両方を付与する。
major_question_tag_groups = [
  { id_start: 1, question_range: 1..200 },
  { id_start: 441, question_range: 201..800 }
]

question_tags = major_question_tag_groups.flat_map do |group|
  question_tag_id = group[:id_start]

  group[:question_range].each_slice(100).flat_map do |questions|
    questions.flat_map do |question_id|
      question_number = question_id - questions.first + 1

      if question_number <= 20
        records = [
          { id: question_tag_id, question_id:, tag_id: 2 },
          { id: question_tag_id + 1, question_id:, tag_id: 3 }
        ]
        question_tag_id += 2
        records
      elsif question_number <= 50
        record = { id: question_tag_id, question_id:, tag_id: 2 }
        question_tag_id += 1
        record
      else
        record = { id: question_tag_id, question_id:, tag_id: 1 }
        question_tag_id += 1
        record
      end
    end
  end
end

QuestionTag.where(question_id: 1..800, tag_id: [1, 2, 3]).delete_all
QuestionTag.seed(:id, question_tags)
