module HasEnqueueControl
  extend ActiveSupport::Concern
  include GoodJob::ActiveJobExtensions::Concurrency

  class_methods do
    def enqueue_limit(limit = 1)
      good_job_control_concurrency_with(
        total_limit: limit,
        key: "enqueue_control_#{self.name.underscore}",
        drop: true
      )
    end
  end
end
