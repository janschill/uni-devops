# Stalker

Stalking website with respect.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stalker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install stalker

## Usage

Start Stalker by exectuting its Rake task. This will start Stalker to hit the websites specified in the `sites.yml` with an interval of 1 second. The interval can be set, but it needs to be at least 1 second.

```bash
bundle exec rake stalker:start[1]
```

It can be stopped by just stopping to process with `CTRL + C` or `kill __pid__` that is being printed to the console.

```bash
bundle exec rake stalker:stop
```

It can also be run in the background like this. Make sure to note down the PID, to be able to kill the process. The PID can also be found with `ps`.

```bash
nohup bundle exec rake stalker:start[1] --trace > rake.out 2>&1 &
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/stalker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/stalker/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Stalker project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/stalker/blob/master/CODE_OF_CONDUCT.md).
