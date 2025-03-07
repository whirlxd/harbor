# README

## Local development

```sh
# Set it up...
git clone https://github.com/hackclub/harbor && cd harbor

# Set your config
cp .env.example .env

# THIS IS THE PART WHERE YOU EDIT YOUR CONFIG
vim .env

# need your local db to be encrypted for some reason? Sure! Replace all the
# secrets with the output of this:
bin/rails runner "puts SecureRandom.base64"
# not guaranteed to be secure for production, but fine for local development


# Build the project


