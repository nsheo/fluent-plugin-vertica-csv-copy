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
$ bundler
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
  port 5433
  username taro
  password abcdefg
  database fluentd
  schema VTCD
  table test
  
  #table columns to input
  column_names id,txt,txt2,txt3,created_at
  #pipeline variabe that read from input, need to match sequence column_names 
  key_names id,txt,txt2,txt3,#{time}
  
  #buffer option
  buffer_type file
  buffer_path /var/log/fluent/test.*.buffer
  flush_interval 60s
  
  #set local_node_run on Vertica node server, you can run copy from local
  #default false
  local_node_run true 
  
  #if you don't want to make create those files, put empty
  rejected_path /path/to/create_rejected_data
  exception_path /path/to/create_exception_data
</match>
```

You can copy and paste generated documents here.

## Copyright

* Copyright(c) 2021- nsheo
* License
  * Apache License, Version 2.0
