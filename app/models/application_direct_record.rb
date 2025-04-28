class ApplicationDirectRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: :primary_direct
end
