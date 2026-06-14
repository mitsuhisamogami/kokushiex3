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
    @score_trend_data = score_trend_data(examinations_scope)
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

  def score_trend_data(examinations_scope)
    examinations_scope.reorder(attempt_date: :asc, created_at: :asc).map do |examination|
      score_trend_item(examination)
    end
  end

  def score_trend_item(examination)
    score_trend_metadata(examination).merge(
      score_trend_scores(examination.score, examination.test.pass_mark)
    )
  end

  def score_trend_metadata(examination)
    {
      label: examination.attempt_date.strftime('%Y/%m/%d'),
      test: examination.test.decorate.implementation_year
    }
  end

  def score_trend_scores(score, pass_mark)
    {
      percentage: score_percentage(score.total_score, pass_mark.total_score),
      pass_percentage: score_percentage(pass_mark.required_score, pass_mark.total_score),
      total_score: score.total_score,
      required_score: pass_mark.required_score,
      full_score: pass_mark.total_score
    }
  end

  def score_percentage(score, full_score)
    (score.to_f / full_score * 100).round(1)
  end
end
