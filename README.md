# ActiveShrine

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/active_shrine`. To experiment with that code, run `bin/console` for an interactive prompt.

## Quick Start

Get ActiveShrine up and running in your Rails application with these simple steps:

1. **Add Plutonium to your Gemfile:**

```ruby
gem "active_shrine"
```

2. **Bundle Install:**

```shell
bundle
```

3. **Install ActiveShrine:**

```shell
rails g active_shrine:install
```

## Usage

```ruby
class Blog < ApplicationRecord
  include ActiveShrine::Model

  has_one_attached :avatar
  has_many_attached :documents
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_shrine. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/active_shrine/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveShrine project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/active_shrine/blob/main/CODE_OF_CONDUCT.md).
