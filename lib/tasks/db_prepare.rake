namespace :db do
  namespace :prepare do
    desc 'Run migrations and load production seed data'
    task production: :environment do
      Rake::Task['db:migrate'].invoke
      SeedFu.seed([Rails.root.join('db/fixtures/production').to_s])
    end

    desc 'Run migrations and load production seed data followed by development-only seed data'
    task development: :environment do
      Rake::Task['db:migrate'].invoke
      SeedFu.seed([Rails.root.join('db/fixtures/production').to_s])
      SeedFu.seed([Rails.root.join('db/fixtures/development').to_s])
    end
  end
end
