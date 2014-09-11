# Poirot Rails

[Poirot](http://instedd.github.io/poirot/) integration for Rails applications.

This gem provides automatic creation of activities on each request, methods for adding arbitrary metadata to them, pushing to a Poirot Receiver, and a Bert connector wrapper for forwarding activity information on calls to Erlang applications.

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

* Server: Poirot receiver where the log entries will be pushed
* Source: name of the application that will be registered as source in Poirot, should be the name of your app
* Enabled: whether Poirot is enabled
* Debug: whether debug-level info is pushed

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

# BERT

A [BERT client](https://github.com/mojombo/bertrpc) that forwards Poirot activity information can be created with `PoirotRails::BertService.new(host, port, timeout)`. This class has the same interface as a standard `BERTRPC::Service` instance.

The [Poirot Erlang](http://github.com/instedd/poirot_erlang) project provides an Ernie implementation that handles this activity info automatically.
