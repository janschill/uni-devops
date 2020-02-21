# MiniTwit

## What is MiniTwit?

This repository is the home of the MiniTwit application, which is a small Twitter clone written in Ruby. It is for a univerisity class DevOps.

## Getting Started

1. Install `rbenv`

* Follow the instructions from their [repository](https://github.com/rbenv/rbenv#basic-github-checkout).
* Make sure it works by running the [rbenv-doctor](https://github.com/rbenv/rbenv-installer/blob/master/bin/rbenv-doctor)

2. Install specified Ruby version from this project using `rbenv`

```bash
$ rbenv install
```

3. Install [Bundler](https://bundler.io/)

```bash
$ gem install bundler
```

4. Install all dependencies from Gemfile

```bash
$ bundle install
```

5. Copy `.env.sample` to `.env` and populate with data

```bash
$ cp .env.sample .env
```

6. Create database

```bash
$ ./bin/control.rb init
```

7. Start server

```bash
$ rackup
```
