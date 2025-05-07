Geocoder.configure(
  timeout: 15,
  lookup: :ipinfo_io,
  ipinfo_api_key: ENV["IPINFO_API_KEY"],
  cache: Geocoder::CacheStore::Generic.new(Rails.cache, {}),
)
