class Neighborhood::Post < ApplicationRecord
  include HasTableSync

  has_table_sync base: "appnsN4MzbnfMY0ai",
                 table: "tbl0iKxglbySiEbB4",
                 pat: ENV["NEIGHBORHOOD_AIRTABLE_PAT"]
end
