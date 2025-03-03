class ApiKey < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: { scope: :user_id }
end
