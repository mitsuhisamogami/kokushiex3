# Sentry is only configured when a DSN is provided via credentials or env.
return unless defined?(Rails)

sentry_dsn = if Rails.application.credentials.respond_to?(:sentry_dsn)
  Rails.application.credentials.sentry_dsn
end
sentry_dsn ||= ENV['SENTRY_DSN']

return if sentry_dsn.blank?

Sentry.init do |config|
  config.dsn = sentry_dsn
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', 0.1).to_f
  config.environment = ENV.fetch('SENTRY_ENVIRONMENT', Rails.env)
  config.enabled_environments = %w[production staging]
end
