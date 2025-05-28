# AGENT.md - Rails Hackatime/Harbor Project

## Commands
- **Tests**: `rails test` (all), `rails test test/models/user_test.rb` (single file), `rails test test/models/user_test.rb -n test_method_name` (single test)
- **Lint**: `bundle exec rubocop` (check), `bundle exec rubocop -A` (auto-fix)
- **Console**: `rails c` (interactive console)
- **Server**: `rails s -b 0.0.0.0` (development server)
- **Database**: `rails db:migrate`, `rails db:create`, `rails db:schema:load`, `rails db:seed`
- **Security**: `bundle exec brakeman` (security audit)

## Docker Development
- Start: `docker compose run --service-ports web /bin/bash`
- Setup DB: `bin/rails db:create db:schema:load db:seed`

## Code Style (rubocop-rails-omakase)
- **Naming**: snake_case files/methods/vars, PascalCase classes, 2-space indent
- **Controllers**: Inherit `ApplicationController`, use `before_action`, strong params with `.permit()`
- **Models**: Inherit `ApplicationRecord`, extensive use of concerns/enums/scopes
- **Error Handling**: `rescue => e` + `Rails.logger.error`, graceful degradation in jobs
- **Imports**: Use `include` for concerns, `helper_method` for view access
- **API**: Namespace under `api/v1/`, structured JSON responses
- **Testing**: Minitest with fixtures, parallel execution enabled
