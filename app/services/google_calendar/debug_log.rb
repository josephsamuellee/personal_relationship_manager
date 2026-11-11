module GoogleCalendar
  # Temporary remote-debug helper. Logs JSON lines to Rails system log for copy/paste.
  # Grep: PRM-DEBUG upcoming-calendar
  module DebugLog
    PREFIX = "[PRM-DEBUG upcoming-calendar]".freeze

    module_function

    def log(hypothesis_id, location, message, data = {})
      payload = {
        hypothesisId: hypothesis_id,
        location: location,
        message: message,
        data: data,
        timestamp: (Time.now.to_f * 1000).to_i
      }
      Rails.logger.warn("#{PREFIX} #{payload.to_json}")
    rescue StandardError
      # never break calendar on debug logging
    end
  end
end
