module Examinations
  class TagScoreSummary
    SECTIONS = {
      practical: {
        label: '実地',
        range: 1..20,
        point: 3,
        note: '実地: 問題1〜20、1問3点'
      },
      specialty: {
        label: '専門',
        range: 21..50,
        point: 1,
        note: '専門: 問題21〜50、1問1点'
      },
      common: {
        label: '共通',
        range: 51..100,
        point: 1,
        note: '共通: 問題51〜100、1問1点'
      }
    }.freeze

    def initialize(examination, questions: nil)
      @examination = examination
      @questions = questions
    end

    def call
      SECTIONS.transform_values { |section| build_section(section) }
    end

    private

    attr_reader :examination

    def build_section(section)
      scores_by_tag = Hash.new { |hash, tag_name| hash[tag_name] = { earned_score: 0, total_score: 0 } }

      questions_for(section).each { |question| add_question_score(scores_by_tag, question, section) }

      {
        label: section[:label],
        note: section[:note],
        tags: serialize_tags(scores_by_tag)
      }
    end

    def add_question_score(scores_by_tag, question, section)
      tag_names = question.tags.map(&:name)
      return if tag_names.blank?

      earned_score = correct_question?(question) ? section[:point] : 0
      tag_names.each do |tag_name|
        scores_by_tag[tag_name][:earned_score] += earned_score
        scores_by_tag[tag_name][:total_score] += section[:point]
      end
    end

    def serialize_tags(scores_by_tag)
      serialized_scores = scores_by_tag.map { |tag_name, score| serialize_tag(tag_name, score) }

      serialized_scores.sort_by { |score| score[:name] }
    end

    def serialize_tag(tag_name, score)
      total_score = score[:total_score]
      earned_score = score[:earned_score]

      {
        name: tag_name,
        earned_score:,
        total_score:,
        percentage: total_score.positive? ? (earned_score.to_f / total_score * 100).round : 0
      }
    end

    def questions_for(section)
      questions.select { |question| section[:range].cover?(question.question_number) }
    end

    def questions
      @questions ||= Question.includes(:tags)
                             .joins(:test_session)
                             .where(test_sessions: { test_id: examination.test_id })
                             .order(:question_number)
                             .to_a
    end

    def correct_question?(question)
      responses_by_question_id.fetch(question.id, []).any? { |response| response.choice.is_correct? }
    end

    def responses_by_question_id
      responses = examination.user_responses.includes(:choice)

      @responses_by_question_id ||= responses.group_by { |response| response.choice.question_id }
    end
  end
end
