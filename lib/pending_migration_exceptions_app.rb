class PendingMigrationExceptionsApp
  def initialize(public_path)
    @public_exceptions = ActionDispatch::PublicExceptions.new(public_path)
  end

  def call(env)
    exception = env["action_dispatch.exception"]
    if exception.is_a?(ActiveRecord::PendingMigrationError)
      html = Rails.root.join("public/pending_migration.html").read
      [503, { "Content-Type" => "text/html; charset=utf-8", "Retry-After" => "60" }, [html]]
    else
      @public_exceptions.call(env)
    end
  end
end
