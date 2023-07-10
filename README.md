# ot-rb

ot-rb is a port of [ot.js](https://github.com/Operational-Transformation/ot.js) for Ruby.

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ot/rb`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ot-rb

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ot-rb

## Usage

```ruby
require 'ot'

operation1 = OT::TextOperation.new
operation1.retain(1)
operation1.delete("o")
operation1.insert("i")
operation1.retain(2)

operation1.apply("hoge") # => "hige"

operation2 = OT::TextOperation.new
operation2.delete("ho")
operation2.insert("mayu")
operation2.retain(2)

operation1t, operation2t = OT::TextOperation.transform(operation1, operation2)

operation2t.apply(operation1.apply("hoge")) # => "mayuige"
operation1t.apply(operation2.apply("hoge")) # => "mayuige"

operation1.compose(operation2t).apply("hoge") # => "mayuige"
operation2.compose(operation1t).apply("hoge") # => "mayuige"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomoasleep/ot-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tomoasleep/ot-rb/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Ot::Rb project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tomoasleep/ot-rb/blob/main/CODE_OF_CONDUCT.md).
