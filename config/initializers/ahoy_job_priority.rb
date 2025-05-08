# Override Ahoy::GeocodeV2Job priority to be low
Ahoy::GeocodeV2Job.class_eval do
  self.priority = 1000
end
