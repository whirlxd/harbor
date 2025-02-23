class Avo::Resources::SailorsLogSlackNotification < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :slack_uid, as: :text
    field :slack_channel_id, as: :text
    field :project_name, as: :text
  end
end
