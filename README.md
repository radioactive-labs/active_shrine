# ActiveShrine

ActiveShrine integrates Shrine file attachments with Active Record models using a familiar API inspired by Active Storage. It provides a simple, flexible way to manage file uploads in your Rails applications while leveraging Shrine's powerful features.

## Features

- **Active Storage-like API**: Familiar `has_one_attached` and `has_many_attached` interface
- **Customizable Uploaders**: Use custom Shrine uploaders with validation, processing, and more
- **Polymorphic Associations**: Attachments are stored using polymorphic associations
- **Eager Loading Support**: Prevent N+1 queries with `with_attached_*` scopes

## Installation

Add ActiveShrine to your application's Gemfile:

```ruby
gem "active_shrine"
```

Then execute:

```bash
$ bundle install
```

Generate and run the migration:

```bash
$ rails generate active_shrine:install
$ rails db:migrate
```

## Basic Usage

Include `ActiveShrine::Model` in your models and declare attachments:

```ruby
class User < ApplicationRecord
  include ActiveShrine::Model

  has_one_attached :avatar
  has_many_attached :photos
end
```

Work with attachments using a familiar API:

```ruby
# Attach a file
user.avatar = File.open("avatar.jpg")
user.save

# Access the attachment
user.avatar.url
user.avatar.content_type
user.avatar.filename

# Remove the attachment
user.avatar = nil
user.save
```

### Eager Loading

Prevent N+1 queries by eager loading attachments:

```ruby
# Single attachment
User.with_attached_avatar

# Multiple attachments
User.with_attached_photos
```

## Custom Uploaders

Define custom uploaders with Shrine features and validations:

```ruby
class ImageUploader < Shrine
  plugin :validation_helpers
  plugin :derivatives

  Attacher.validate do
    validate_max_size 10 * 1024 * 1024
    validate_mime_type %w[image/jpeg image/png image/webp]
  end
  
  Attacher.derivatives do |original|
    {
      small: shrine_derivative(:resize_to_limit, 300, 300),
      medium: shrine_derivative(:resize_to_limit, 500, 500)
    }
  end
end
```

Use custom uploaders in your models:

```ruby
class User < ApplicationRecord
  include ActiveShrine::Model

  has_one_attached :avatar, uploader: ::ImageUploader
end
```

## Development

After checking out the repo:

1. Run `bin/setup` to install dependencies
2. Run `bundle exec rake test` to run the tests
3. Run `bin/console` for an interactive prompt

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_shrine.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveShrine project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/active_shrine/blob/main/CODE_OF_CONDUCT.md).