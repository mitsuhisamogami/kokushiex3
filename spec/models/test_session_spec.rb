# == Schema Information
#
# Table name: test_sessions
#
#  id         :bigint           not null, primary key
#  session    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  test_id    :bigint           not null
#
# Indexes
#
#  index_test_sessions_on_test_id  (test_id)
#
# Foreign Keys
#
#  fk_rails_...  (test_id => tests.id)
#
require 'rails_helper'

RSpec.describe TestSession do
  pending "add some examples to (or delete) #{__FILE__}"
end
