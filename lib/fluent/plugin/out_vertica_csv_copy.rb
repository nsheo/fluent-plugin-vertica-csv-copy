#
# Copyright 2021- nsheo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/output"

module Fluent
  module Plugin
    class VerticaCsvCopyOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("vertica_csv_copy", self)

      helpers :compat_parameters, :inject

      QUERY_TEMPLATE_RJT = "COPY %s.%s (%s) FROM STDIN DELIMITER '|' RECORD TERMINATOR E'\n' ENFORCELENGTH ABORT ON ERROR NULL '' REJECTED DATA AS TABLE '%s' DIRECT STREAM NAME '%sFluentd%d'"
      
      QUERY_TEMPLATE = "COPY %s.%s (%s) FROM STDIN DELIMITER '|' RECORD TERMINATOR E'\n' ENFORCELENGTH ABORT ON ERROR NULL '' DIRECT STREAM NAME '%sFluentd%d'"
      
#      QUERY_TEMPLATE_RJF1 = "COPY %s.%s (%s) FROM STDIN DELIMITER '|' RECORD TERMINATOR E'\n' ENFORCELENGTH ABORT ON ERROR NULL '' REJECTED DATA '%s' ON %s DIRECT STREAM NAME '%sFluentd%d'"
      
#      QUERY_TEMPLATE_RJF2 = "COPY %s.%s (%s) FROM STDIN DELIMITER '|' RECORD TERMINATOR E'\n' ENFORCELENGTH ABORT ON ERROR NULL '' REJECTED DATA '%s' ON %s EXCEPTIONS '%s' ON %s DIRECT STREAM NAME '%sFluentd%d'"
 
      def initialize
        super
        require 'vertica'
        require 'tempfile'
      end 
	  
      config_param :host,           :string,  :default => '127.0.0.1', desc: "Database host"
      config_param :port,           :integer, :default => 5433, desc: "Database port"
      config_param :username,       :string,  :default => 'dbadmin', desc: "Database user"
      config_param :password,       :string,  :default => nil, desc: "Database password"
      config_param :database,       :string,  :default => nil, desc: "Database name"
      config_param :schema,         :string,  :default => nil, desc: "Database schema"
      config_param :table,          :string,  :default => nil, desc: "Database target table"
      config_param :column_names,   :string,  :default => nil, desc: "Column names for data load"
      config_param :key_names,      :string,  :default => nil, desc: "fleuntd target key, time can be override ${time}" 
      config_param :reject_type,    :string,  :default => 'none', desc: "Rejected data type to save (none/table)" 
      config_param :reject_target,  :string,  :default => nil, desc: "Table for rejected data" 
#      config_param :exception_path, :string,  :default => nil, desc: "When reject_type is file, path to create exceptions" 
#      config_param :node_target,    :string,  :default => nil, desc: "When reject_type is file, target node to make rejected/exception file"
      config_param :ssl,            :bool,    :default => false, desc: "Database ssl connection info"
	  
      def configure(conf)
        compat_parameters_convert(conf, :buffer, :inject)
        super
        if @database.nil? || @table.nil? || @column_names.nil? || @schema.nil?
          raise Fluent::ConfigError, "database and schema and tablename and column_names is required."
        end
		
        @key_names = @key_names.nil? ? @column_names.split(',') : @key_names.split(',')
        unless @column_names.split(',').count == @key_names.count
          raise Fluent::ConfigError, "It does not take the integrity of the key_names and column_names."
        end
      end
	  
      def start
        super
      end
	  
      def shutdown
        super
      end
	  
      def format(tag, time, record)
        record = inject_values_to_record(tag, time, record)
        [tag, time, record].to_msgpack
      end
	  
      def formatted_to_msgpack_binary
        true
      end
	  
      def multi_workers_ready?
        true
      end
	  
      def expand_placeholders(metadata)
        database = extract_placeholders(@database, metadata).gsub('.', '_')
        table = extract_placeholders(@table, metadata).gsub('.', '_')
        return database, table
      end
	  
      def write(chunk)
        #log.info "Data reformatting start"
        database, table = expand_placeholders(chunk.metadata)
        data_count = 0
        tmp = Tempfile.new("vertica-copy-temp")
        chunk.msgpack_each do |tag, time, data|
          tmp.write format_proc.call(tag, time, data).join("|") + "\n"
          data_count += 1
          #log.info "Check result %s" %([format_proc.call(tag, time, data).join("|")])
        end	
        #log.info "Data Check \"%s\"" % ([tmp.read])
        tmp.close
        
        current_time = (Time.now.to_f * 1000).round

    #    if @reject_type == 'none'
    #      vertica.copy(QUERY_TEMPLATE % ([@schema, @table, @column_names, @table, current_time]), source: tmp.path)
    #    elsif @reject_type == 'table'
    #      if @reject_target.nil? 
    #        log.warn "Rejected Data target Table is empty"
    #        vertica.copy(QUERY_TEMPLATE % ([@schema, @table, @column_names, @table, current_time]), source: tmp.path)
    #      else 
    #        vertica.copy(QUERY_TEMPLATE_RJT % ([@schema, @table, @column_names, @reject_target, @table, current_time]), source: tmp.path)
    #      end
    #    else
    #      if @exception_path.nil? 
    #        if @reject_target.nil? 
    #          log.warn "Rejected Data target path / Exception file path is empty"
    #          vertica.copy(QUERY_TEMPLATE % ([@schema, @table, @column_names, @table, current_time]), source: tmp.path)
    #        else 
    #          log.warn "Exception file path is empty"
    #          vertica.copy(QUERY_TEMPLATE_RJF1 % ([@schema, @table, @column_names, @reject_target, @node_target, @table, current_time]), source: tmp.path)
    #        end
    #      else 
    #        vertica.copy(QUERY_TEMPLATE_RJF2 % ([@schema, @table, @column_names, @reject_target, @node_target, @exception_path, @node_target, @table, current_time]), source: tmp.path)
    #      end
    #    end
        
        if @reject_type == 'none'
          vertica.copy(QUERY_TEMPLATE % ([@schema, @table, @column_names, @table, current_time]), source: tmp.path)
        else
          if @reject_target.nil? 
            log.warn "Rejected Data target Table is empty"
            vertica.copy(QUERY_TEMPLATE % ([@schema, @table, @column_names, @table, current_time]), source: tmp.path)
          else 
            vertica.copy(QUERY_TEMPLATE_RJT % ([@schema, @table, @column_names, @reject_target, @table, current_time]), source: tmp.path)
          end
        end
      
        vertica.close
        @vertica = nil
        log.info "Stream Data \"%s:%s:%s:%sFluentd%d:%d\"" % ([@database, @schema, @table, @table, current_time, data_count])
      end
      
	  
      private
	  
      def format_proc
        proc do |tag, time, record|
          values = []
          @key_names.each_with_index do |key, i|
            if key == '${time}'
              value = Time.at(time).strftime('%Y-%m-%d %H:%M:%S')
            else
              value = record[key]
            end
            values << value
          end
          values
        end
      end
      
	  
      def vertica
        @vertica ||= Vertica.connect({
          :host     => @host,
          :user     => @username,
          :password => @password,
          :ssl      => @ssl,
          :port     => @port,
          :database => @database
        })
      end
    end
  end
end
