PaperTrail.config.track_associations = false
PaperTrail.config.enabled = true

Rails.application.config.to_prepare do
  PaperTrail::Version.module_eval do
    belongs_to :item, polymorphic: true
    belongs_to :user, optional: true
  end
end
