class HackatimeRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: { reading: :wakatime, writing: :wakatime }
end
