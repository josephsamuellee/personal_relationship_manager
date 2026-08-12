if Rails.env.production?
  require Rails.root.join("lib/pending_migration_exceptions_app")

  Rails.application.config.exceptions_app = PendingMigrationExceptionsApp.new(Rails.public_path)
end
