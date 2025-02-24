class Avo::Resources::SailorsLogLeaderboard < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :slack_channel_id, as: :text
    field :slack_uid, as: :text
    field :message, as: :textarea, placeholder: "Generating..."
  end
end
