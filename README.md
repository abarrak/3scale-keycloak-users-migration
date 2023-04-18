# Keycloak 3scale Users Migration

[![CI (build & test)](https://github.com/abarrak/3scale-keycloak-users-migration/actions/workflows/ci.yml/badge.svg)](https://github.com/abarrak/3scale-keycloak-users-migration/actions/workflows/ci.yml) [![Gem Version](https://badge.fury.io/rb/keycloak_3scale_users.svg)](https://badge.fury.io/rb/keycloak_3scale_users)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keycloak_3scale_users'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install keycloak_3scale_users

## Usage

After installation, use the binary to apply the migrate operation.

Pass the required arguments as follows:

```bash
keycloak_3scale_users <3scale-api-base-url> <3scale-token> <keycloak-url> <keycloak-realm-name> <keyclock_client_id> <keyclock-admin-user> <keycloak-admin-password> <main-redirect-url>
```

(Poor's man positional only).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/keycloak_3scale_users.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
