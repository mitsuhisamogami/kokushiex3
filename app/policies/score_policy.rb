# frozen_string_literal: true

class ScorePolicy < ApplicationPolicy
  # スコアの詳細表示は、そのスコアに紐づくexaminationの所有者のみ
  def show?
    record.examination.user == user
  end

  # スコアの作成・更新・削除は不可（システムが自動生成）
  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:examination).where(examinations: { user: user })
    end
  end
end
