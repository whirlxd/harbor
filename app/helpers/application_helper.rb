module ApplicationHelper
  def cache_stats
    hits = Thread.current[:cache_hits] || 0
    misses = Thread.current[:cache_misses] || 0
    { hits: hits, misses: misses }
  end

  def admin_tool(class_name = "", element = "div", **options, &block)
    return unless current_user&.is_admin?
    concat content_tag(element, class: "admin-tool #{class_name}", **options, &block)
  end

  def short_time_simple(time)
    hours = time.to_i / 3600
    minutes = (time.to_i % 3600) / 60

    time_parts = []
    time_parts << "#{hours}h" if hours.positive?
    time_parts << "#{minutes}m" if minutes.positive?
    time_parts.join(" ")
  end

  def short_time_detailed(time)
    hours = time.to_i / 3600
    minutes = (time.to_i % 3600) / 60
    seconds = time.to_i % 60

    time_parts = []
    time_parts << "#{hours}h" if hours.positive?
    time_parts << "#{minutes}m" if minutes.positive?
    time_parts << "#{seconds}s" if seconds.positive?
    time_parts.join(" ")
  end
end
