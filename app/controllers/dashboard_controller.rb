class DashboardController < ApplicationController
  EXAMINATIONS_PER_PAGE = 10

  before_action :authenticate_user!

  def index
    examinations_scope = ordered_examinations
    @total_examinations_count = examinations_scope.count
    @total_history_pages = total_history_pages
    @history_page = requested_page.clamp(1, @total_history_pages)
    @latest_examination = examinations_scope.first
    @latest_score = @latest_examination&.score
    @examinations = examinations_scope
                    .offset((@history_page - 1) * EXAMINATIONS_PER_PAGE)
                    .limit(EXAMINATIONS_PER_PAGE)
  end

  private

  def ordered_examinations
    current_user
      .examinations
      .includes(:score, test: :pass_mark)
      .order(attempt_date: :desc, created_at: :desc)
  end

  def requested_page
    params[:page].to_i
  end

  def total_history_pages
    [(@total_examinations_count.to_f / EXAMINATIONS_PER_PAGE).ceil, 1].max
  end
end
