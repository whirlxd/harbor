class Heartbeat < ApplicationRecord
  before_save :set_fields_hash!

  # This is to prevent Rails from trying to use STI even though we have a "type" column
  self.inheritance_column = nil

  belongs_to :user

  validates :time, presence: true

  private

  def set_fields_hash!
    # only if the field exists in activerecord
    if self.class.column_names.include?("fields_hash")
      self.fields_hash = Digest::MD5.hexdigest(self.attributes.except("id", "created_at", "updated_at").to_json)
    end
  end
end
