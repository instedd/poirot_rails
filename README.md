# Poirot Rails

[Poirot](http://instedd.github.io/poirot/) integration for Rails applications.

This gem provides automatic creation of activities on each request and backend job, methods for adding arbitrary metadata to them, pushing to a Poirot Receiver, log file or standard output.

It also provides a Bert connector wrapper for forwarding activity information on calls to Erlang applications.

# Installation

Add to your `Gemfile`
```ruby
gem 'poirot_rails', :git => "https://bitbucket.org/instedd/poirot_rails", :branch => 'master'
```

# Usage

Add a file `poirot.yml` to your `config` directory to configure the gem, with a node per environment. Example:
```
common: &default_settings
  server: localhost:2120
  source: my-app
  debug: false

development:
  <<: *default_settings
  enabled: true
  debug: true

production:
  <<: *default_settings
  enabled: false

test:
  <<: *default_settings
  enabled: false
```

## Properties

The supported properties are:

* **enabled**: whether Poirot is enabled
* **server**: URL of the Poirot receiver where the log entries will be pushed
* **debug**: whether to write Poirot entries to a `log/poirot_#{Rails.environment}.log` file
* **source**: name of the application that will be registered as source in Poirot; this should be the name of your app
* **stdout**: whether to send Poirot entries to STDOUT
* **suppress_rails_log**: whether to silence the configured Rails logger

# Activities

Activities can be managed via the class `PoirotRails::Activity`. The easiest thing to do is add custom metadata to the current activity, which is linked to the current request. Example:
```
PoirotRails::Activity.current.merge! user: current_user.email
```

A block can be executed in the context of a new activity by invoking `PoirotRails::Activity.start` with a block to be tracked within that activity. The new activity will be pushed as a child of the current activity. Example:
```
PoirotRails::Activity.start("Send email notifications", emails: emails) do
  emails.each do |email|
    send_notification_to email
  end
end
```

Refer to the implementation of the class `PoirotRails::Activity` for more details.

## Requests

Every web request is automatically wrapped in a new Poirot Activity, so all log entries generated within a request will belong to the same activity.

## Active Job

The same applies to active jobs: all actions executed during an active job will be logged as part of the same activity.

## Net:HTTP requests

Requests sent using Net HTTP will also be wrapped within a new activity, and a `X-Poirot-Activity-Id` header will be added to the request, so if the recipient of the request is also Poirot-aware, can link the new activity to the originator.

# BERT

A [BERT client](https://github.com/mojombo/bertrpc) that forwards Poirot activity information can be created with `PoirotRails::BertService.new(host, port, timeout)`. This class has the same interface as a standard `BERTRPC::Service` instance.

The [Poirot Erlang](http://github.com/instedd/poirot_erlang) project provides an Ernie implementation that handles this activity info automatically.

