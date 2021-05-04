# fluent-plugin-vertica-csv-copy

[Fluentd](https://fluentd.org/) output plugin to do something.

**!! IMPORTANT : This Plugin in development.** 

## Installation

### RubyGems

```
$ gem install fluent-plugin-vertica-csv-copy
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-vertica-csv-copy"
```

And then execute:

```
$ bundle
```

## Configuration

You can generate configuration template:

```
$ fluent-plugin-config-format output vertica-csv-copy
```

```
<match loaddata.**>
  type vertica_csv_copy
  host localhost
  port 3306
  username taro
  password abcdefg
  database fluentd
  tablename test
  column_names id,txt,txt2,txt3,created_at
  key_names id,txt,txt2,txt3,#{time}

  buffer_type file
  buffer_path /var/log/fluent/test.*.buffer
  flush_interval 60s
</match>
```

You can copy and paste generated documents here.

## Copyright

* Copyright(c) 2021- nsheo
* License
  * Apache License, Version 2.0
