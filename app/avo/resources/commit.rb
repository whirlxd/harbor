class Avo::Resources::Commit < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :sha, as: :text
    field :user, as: :belongs_to
    field :github_raw, as: :code
  end
end
