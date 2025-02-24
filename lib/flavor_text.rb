class FlavorText
  def self.loading_messages
    [
      "Generating leaderboard...",
      "Crunching the numbers...",
      "Hold tight, I'm working on it...",
      "chugging the data juice",
      "chugging *Stat-Cola©*, for those who want to know things™",
      "that's numberwang!",
      "crunching the numbers",
      "munching the numbers",
      "gurgling the bits",
      "juggling the electrons",
      "chomping the bytes",
      "playing the photons on bass",
      "reticulating the splines",
      "rolling down data hills",
      "frolicking through fields of numbers",
      "skiing the data slopes",
      "dropping in and sending it",
      "zooming through the cyber-pipes",
      "grabbing the stats",
      "switching the dependent and independent variables",
      "flipping a coin to choose which axis to use",
      "warming up the powerhouse of the cell",
      "calculating significant figures...",
      "calculating insignificant figures...",
      "p-hacking the n value",
      "computing P = NP",
      "realizing P ≠ NP",
      "so, uh... come here often?",
      "*powertool noises*",
      "*frantic typing noises*",
      "*keyboard clacking noises*",
      "*crunching number noises*",
      "*beep* *beep* *beep*",
      "carrying the one",
      "team-carrying the one",
      "carrying the zero",
      "ganking the one before it gets carried",
      "spinning violently around the y-axis",
      "#{%w[tokenizing serializing stringifying].sample} #{[ "blood, sweat, & tears", "the human condition", "personal experiences", "elbow grease" ].sample}",
      "waking up the bits",
      "petting the bits",
      "testing patience",
      "[npm] now installing #{rand(3..7)} of #{rand(26_000..29_000)} packages",
      "spinning the rgbs",
      "Installing dependencies",
      "shoveling the overflowed pixels",
      ".split() === :large_blue_circle::large_green_circle::large_yellow_circle::large_orange_circle::red_circle::large_purple_circle:",
      "Are ya' winning, son?",
      "Dropkicking the cache into the sun",
      "[#{self.other_servers.sample}] starting on port #{self.common_ports.sample}",
      "compressing the accountants"
    ]
  end

  def self.common_ports
    %w[
      80
      443
      3000
      3001
      3002
    ]
  end

  def self.other_servers
    %w[
      express
      django
      flask
      ngrok
      nextjs
    ]
  end

  def self.other_languages
    %w[
      bash
      bunjs
      c
      c#
      c++
      go
      java
      javascript
      kotlin
      perl
      php
      python
      rust
      swift
    ]
  end

  def self.rare_loading_messages
    [
      "I would like to thank the academy...",
      "If you really think about it, isn't coffee just refried bean water?",
      "I'd be faster if I was written in #{self.other_languages.sample}",
      "Loading better loading messages..."
    ]
  end
end
