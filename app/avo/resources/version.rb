class Avo::Resources::Version < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  self.model_class = PaperTrail::Version

  def fields
    field :id, as: :id
    field :item_type, as: :text
    field :item_id, as: :number
    field :event, as: :text
    field :whodunnit, as: :text
    field :object, as: :code
    field :created_at, as: :date_time
  end
end
