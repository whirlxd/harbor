class Avo::Resources::Heartbeat < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :text
    field :entity, as: :textarea
    field :type, as: :textarea
    field :category, as: :text
    field :time, as: :date_time
    field :project, as: :text
    field :project_root_count, as: :number
    field :branch, as: :text
    field :language, as: :text
    field :dependencies, as: :text
    field :lines, as: :number
    field :line_additions, as: :number
    field :line_deletions, as: :number
    field :lineno, as: :number
    field :cursorpos, as: :number
    field :is_write, as: :boolean
  end
end
