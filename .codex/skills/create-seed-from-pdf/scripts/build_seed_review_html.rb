#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'fileutils'
require 'optparse'

options = {
  root: Dir.pwd
}

OptionParser.new do |parser|
  parser.banner = 'Usage: ruby build_seed_review_html.rb --exam EXAM [--seeds PATH,PATH] [--output PATH] [--title TITLE]'
  parser.on('--exam EXAM', 'Exam number, such as 61') { |value| options[:exam] = value }
  parser.on('--seeds PATHS', 'Comma-separated seed paths. Defaults to db/fixtures/development/*test_<exam>_*.rb') do |value|
    options[:seeds] = value.split(',').map(&:strip)
  end
  parser.on('--output PATH', 'Output HTML path. Defaults to tmp/seed_review_<exam>.html') { |value| options[:output] = value }
  parser.on('--title TITLE', 'HTML title text') { |value| options[:title] = value }
  parser.on('--root PATH', 'Repository root. Defaults to current directory') { |value| options[:root] = value }
end.parse!

abort '--exam is required' if options[:exam].to_s.empty?

root = File.expand_path(options[:root])
exam = options[:exam].to_s
seed_paths = options[:seeds] || Dir.glob(File.join(root, "db/fixtures/development/*test_#{exam}_*.rb")).sort
abort "No seed files found for exam #{exam}" if seed_paths.empty?

output_path = File.expand_path(options[:output] || File.join(root, "tmp/seed_review_#{exam}.html"), root)
title = options[:title] || "第#{exam}回 理学療法士国家試験 seed確認"

class SeedReviewCapture
  @records = Hash.new { |hash, key| hash[key] = [] }

  class << self
    attr_reader :records

    def capture(model_name, rows)
      records[model_name].concat(rows)
    end
  end
end

class Test
  def self.seed(_key, rows)
    SeedReviewCapture.capture(:tests, rows)
  end
end

class TestSession
  def self.seed(_key, rows)
    SeedReviewCapture.capture(:test_sessions, rows)
  end
end

class Question
  def self.seed(_key, rows)
    SeedReviewCapture.capture(:questions, rows)
  end
end

class Choice
  def self.seed(_key, rows)
    SeedReviewCapture.capture(:choices, rows)
  end
end

def h(value)
  CGI.escapeHTML(value.to_s)
end

def image_exists?(root, image_url)
  image_url && File.exist?(File.join(root, 'public', image_url))
end

def likely_needs_image?(content)
  content.match?(/図に示す|写真.*示す|別冊|心電図モニター|X線写真|X線画像|MRI画像|画像.*示す|波形.*別|表を示す|結果を示す/)
end

seed_paths.each do |path|
  eval(File.read(path), TOPLEVEL_BINDING, path)
end

sessions = SeedReviewCapture.records.fetch(:test_sessions, []).to_h { |row| [row[:id], row] }
questions = SeedReviewCapture.records.fetch(:questions, []).sort_by { |row| [row[:test_session_id], row[:question_number]] }
choices_by_question = SeedReviewCapture.records.fetch(:choices, []).group_by { |row| row[:question_id] }

html = <<~HTML
  <!doctype html>
  <html lang="ja">
  <head>
    <meta charset="utf-8">
    <title>#{h(title)}</title>
    <style>
      body { margin: 0; color: #172026; background: #f5f7f8; font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Yu Gothic", sans-serif; line-height: 1.65; }
      header { position: sticky; top: 0; z-index: 1; padding: 14px 24px; background: #fff; border-bottom: 1px solid #d7dee2; }
      h1 { margin: 0; font-size: 20px; }
      main { max-width: 1120px; margin: 0 auto; padding: 24px; }
      section { margin-bottom: 18px; padding: 18px; background: #fff; border: 1px solid #d7dee2; border-radius: 8px; }
      h2 { margin: 0 0 10px; font-size: 18px; }
      .meta { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px; }
      .badge { padding: 2px 8px; border: 1px solid #b9c3c9; border-radius: 999px; background: #f8fafb; font-size: 13px; }
      .warn { border-color: #d48b00; background: #fff7e6; color: #7a4b00; }
      .error { border-color: #c83532; background: #fff0f0; color: #8f1f1d; }
      .question { white-space: pre-wrap; font-size: 16px; }
      .image-wrap { margin: 14px 0; padding: 12px; border: 1px solid #e1e6e9; background: #fbfcfd; }
      img { max-width: 100%; max-height: 560px; display: block; margin: 0 auto; }
      ol { margin: 12px 0 0; padding-left: 28px; }
      li { margin: 6px 0; }
      .correct { font-weight: 700; color: #0f6b3f; }
      .path { margin-top: 6px; color: #61717b; font-size: 13px; word-break: break-all; }
    </style>
  </head>
  <body>
  <header><h1>#{h(title)}</h1></header>
  <main>
HTML

questions.each do |question|
  session = sessions.fetch(question[:test_session_id])
  choices = choices_by_question.fetch(question[:id], []).sort_by { |row| row[:option_number] }
  correct_choices = choices.select { |row| row[:is_correct] }
  image_url = question[:image_url]
  image_ok = image_exists?(root, image_url)
  expects_two = question[:content].include?('2つ選べ')

  checks = []
  checks << ['選択肢数5件ではありません', 'error'] unless choices.size == 5
  checks << ['正答なし', 'error'] if correct_choices.empty?
  checks << ['「2つ選べ」ですが正答数が2件ではありません', 'error'] if expects_two && correct_choices.size != 2
  checks << ['画像ファイルが見つかりません', 'error'] if image_url && !image_ok
  checks << ['画像なし（PDF/別冊確認）', 'warn'] if image_url.nil? && likely_needs_image?(question[:content])

  session_label = session[:session] == 'AM' ? '午前' : '午後'

  html << <<~HTML
    <section id="#{h(session[:session].downcase)}-#{h(question[:question_number])}">
      <h2>#{h(session_label)} 問#{h(question[:question_number])}</h2>
      <div class="meta">
        <span class="badge">question_id: #{h(question[:id])}</span>
        <span class="badge">正答数: #{h(correct_choices.size)}</span>
  HTML

  checks.each do |label, klass|
    html << %Q(      <span class="badge #{klass}">#{h(label)}</span>\n)
  end

  html << <<~HTML
      </div>
      <div class="question">#{h(question[:content])}</div>
  HTML

  if image_url
    html << <<~HTML
      <div class="image-wrap">
        #{image_ok ? %Q(<img src="../public/#{h(image_url)}" alt="#{h(session_label)} 問#{h(question[:question_number])}">) : ''}
        <div class="path">#{h(image_url)}</div>
      </div>
    HTML
  end

  html << "      <ol>\n"
  choices.each do |choice|
    klass = choice[:is_correct] ? ' class="correct"' : ''
    mark = choice[:is_correct] ? ' [正答]' : ''
    html << %Q(        <li#{klass}>#{h(choice[:content])}#{mark}</li>\n)
  end
  html << "      </ol>\n"
  html << "    </section>\n"
end

html << <<~HTML
  </main>
  </body>
  </html>
HTML

FileUtils.mkdir_p(File.dirname(output_path))
File.write(output_path, html)
puts output_path
