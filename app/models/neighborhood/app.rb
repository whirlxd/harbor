class Neighborhood::App < ApplicationRecord
  self.table_name = "neighborhood_apps"

  include HasTableSync

  has_table_sync base: "appnsN4MzbnfMY0ai",
                 table: "tbls2fHyQYCtCbYbl",
                 pat: ENV["NEIGHBORHOOD_AIRTABLE_PAT"]
end
