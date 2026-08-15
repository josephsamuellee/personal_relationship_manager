class ServerStatistics
  BYTES_PER_MB = 1024 * 1024

  def initialize(database_path: nil)
    @database_path = database_path
  end

  def database_size_mb
    path = resolved_database_path
    return nil if path.blank? || !File.file?(path)

    File.size(path).to_f / BYTES_PER_MB
  rescue StandardError
    nil
  end

  def formatted_database_size
    size = database_size_mb
    return "Unavailable" if size.nil?

    format("%.2f MB", size.round(2))
  end

  def total_entries
    Entry.count
  end

  def entries_created_last_30_days
    Entry.where(created_at: 30.days.ago..Time.current).count
  end

  private

  def resolved_database_path
    return @database_path if @database_path.present?

    configured = ActiveRecord::Base.connection_db_config.configuration_hash[:database]
    return if configured.blank?

    File.expand_path(configured, Rails.root)
  rescue StandardError
    nil
  end
end
