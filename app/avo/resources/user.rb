class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :slack_uid, as: :text
    field :email, as: :text
    field :username, as: :text
    field :avatar_url, as: :text
  end
end


