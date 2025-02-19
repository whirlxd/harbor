# 🔧🐒

Rails.configuration.to_prepare do
  Avo::BaseApplicationController.class_eval do
    before_action :set_paper_trail_whodunnit
    def user_for_paper_trail
      Avo::Current.user&.id
    end
  end

  PaperTrail::Version.class_eval do
    def user
      begin
        User.find(whodunnit) if whodunnit
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end

