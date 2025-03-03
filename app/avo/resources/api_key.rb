class Avo::Resources::ApiKey < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :user, as: :text
    field :name, as: :textarea
    field :token, as: :textarea
  end
end


