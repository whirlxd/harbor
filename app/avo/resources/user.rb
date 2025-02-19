class Avo::Resources::User < Avo::BaseResource
  self.title = :email
  self.includes = []

  def fields
    field :id, as: :id
    field :email, as: :text
    field :username, as: :text
    field :slack_uid, as: :text
    field :avatar_url, as: :text
    field :is_admin, as: :boolean
    field :created_at, as: :date_time, readonly: true
    field :updated_at, as: :date_time, readonly: true

    # Show versions/history in the show page
    field :versions, as: :has_many
  end
end
