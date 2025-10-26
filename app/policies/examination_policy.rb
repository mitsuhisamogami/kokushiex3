# frozen_string_literal: true

class ExaminationPolicy < ApplicationPolicy
  # 一覧表示は自分のexaminationsのみ
  def index?
    true
  end

  # 詳細表示は所有者のみ
  def show?
    record.user == user
  end

  # 新規作成は認証済みユーザーなら可能
  def create?
    user.present?
  end

  def new?
    create?
  end

  # 試験結果の更新は不可
  def update?
    false
  end

  def edit?
    update?
  end

  # 削除は所有者のみ
  def destroy?
    record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
