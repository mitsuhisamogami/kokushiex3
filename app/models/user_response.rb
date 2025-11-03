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
class UserResponse < ApplicationRecord
  belongs_to :examination
  belongs_to :choice

  scope :correct_responses, -> { joins(choice: :question).where(choices: { is_correct: true }) }

  MAX_RESPONSES = 250

  # insert_allではバリデーションチェックができないためメソッド化
  def self.bulk_create_responses(examination, choice_ids) # rubocop:disable Metrics/MethodLength
    sanitized_ids = sanitize_choice_ids(choice_ids)
    return false if sanitized_ids.blank?

    if sanitized_ids.size > MAX_RESPONSES
      Rails.logger.error "Too many Choice IDs: #{sanitized_ids.size}"
      return false
    end

    choices = Choice.where(id: sanitized_ids)
    if choices.size != sanitized_ids.size
      missing_ids = sanitized_ids - choices.pluck(:id)
      Rails.logger.error "Missing Choice IDs: #{missing_ids.join(', ')}"
      return false
    end

    timestamp = Time.current
    attributes = sanitized_ids.map do |choice_id|
      {
        examination_id: examination.id,
        choice_id:,
        created_at: timestamp,
        updated_at: timestamp
      }
    end

    UserResponse.insert_all(attributes) # rubocop:disable Rails/SkipsModelValidations
    true
  rescue ArgumentError => e
    Rails.logger.error(e.message)
    false
  end

  def self.sanitize_choice_ids(choice_ids)
    numeric_ids = normalize_choice_ids(choice_ids)
    raise ArgumentError, 'choice_ids cannot be blank' if numeric_ids.blank?

    ensure_no_duplicates!(numeric_ids)
    numeric_ids.uniq
  end

  def self.normalize_choice_ids(choice_ids)
    raise ArgumentError, 'choice_ids must be an array' unless choice_ids.is_a?(Array)

    choice_ids.each_with_object([]) do |id, collection|
      if id.is_a?(Integer)
        collection << id
      elsif id.respond_to?(:to_s) && id.to_s =~ /\A\d+\z/
        collection << id.to_s.to_i
      end
    end
  end

  def self.ensure_no_duplicates!(choice_ids)
    duplicates = choice_ids.each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }
                           .select { |_value, count| count > 1 }
                           .keys
    raise ArgumentError, "Duplicate Choice IDs detected: #{duplicates.join(', ')}" if duplicates.present?
  end
  private_class_method :sanitize_choice_ids, :normalize_choice_ids, :ensure_no_duplicates!
end
