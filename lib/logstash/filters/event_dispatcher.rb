# encoding: utf-8
require 'json'
require "logstash/filters/base"
require "logstash/namespace"

# This filter has a wrapper "filter" object (@filter) which contains a list of "filter_part" objects.
# Each "filter_part" can be a wrapped filter plugin object or a (nested) wrapper "filter" object.
#
# The "filter" object is defined in the configuration json file provided by the user at this location:  "#{@config_dir}/#{@config_json_filename}" .
# It is instantiated when the "register" method is called.
# All filter plugin objects contained in the "filter" object also get instatialed/registered at this time.
#
# When the "filter" method is called, it simply delegates the call to the "filter" object's "filter" method
# which in turns calls the "filter" methods of the contained "filter_part" objects.
# The final outcome of the "filter" method call is entirely determined by the control flow logic defined in
# the confguration json file provided by the user
#
class LogStash::Filters::Event_dispatcher < LogStash::Filters::Base

  config_name "event_dispatcher"

  # Local file folder path where the config json file is located
  config :config_dir, :validate => :string, :default => "#{Dir::home()}/tmp/event_dispatcher/config"

  #Name of the config json file
  config :config_json_filename, :validate => :string, :default => "filter.json"

  #Name of event_filter_tag field, the value of this field can be read and/or set by each filter_part
  #for correctly controlling the event's filter path.
  config :event_filter_tag_field, :validate => :string, :default => "event_filter_tag"

  #Name of event_filter_done field, the value of this field is used by each filter_part
  #to determine if it can stop traversing all filter_parts's "filter" methods
  config :event_filter_done_field, :validate => :string, :default => "event_filter_done"

  #Local debug flag
  config :localDebug, :validate => :boolean, :default => false

  def register
    filter_json_file_path = "#{@config_dir}/#{@config_json_filename}"
    @logger.debug? && @logger.debug("Running event_dispatcher register, filter_json_file_path: #{filter_json_file_path}")
    @localDebug && (puts "LD> Running event_dispatcher register, filter_json_file_path: #{filter_json_file_path}")

    filter_json_string = File.read(filter_json_file_path)
    filter_json = JSON.parse(filter_json_string)
    @logger.debug? && @logger.debug("filter_json loaded: #{filter_json}")
    @localDebug && (puts "LD> filter_json loaded: #{filter_json}")

    if resolve_references(filter_json)
      @logger.debug? && @logger.debug("filter_json resolved: #{filter_json}")
      @localDebug && (puts "LD> filter_json resolved: #{filter_json}")
    end

    filter_part_json = { "filter_parts" => filter_json }
    @filter = Filter.new(filter_part_json, @config)

  end

  #resolve any references to ${config_dir} in all path strings
  def resolve_references(filter_json)
    modified = false
    filter_json.each do |part|
      if part["type"] == "filter"
        filter_parts = part["filter_parts"]
        if filter_parts.class == String
          filter_parts_new = filter_parts.gsub("${config_dir}", "#{config_dir}")
          if filter_parts_new != filter_parts
            modified = true
            filter_json_1 = File.read(filter_parts_new)
            filter_parts = JSON.parse(filter_json_1)
            part["filter_parts"] = filter_parts
          end
        end
        if resolve_references(filter_parts)
          modified = true
        end
      elsif part["type"] == "plugin" && part["name"] == "ruby"
        path = part["options"]["path"]
        unless path.nil?
          path_new = path.gsub("${config_dir}", "#{config_dir}")
          if path_new != path
            modified = true
            part["options"]["path"] = path_new
          end
        end
      end
    end
    return modified
  end

  public

  def filter(event)
    @logger.debug? && @logger.debug("Running event_dispatcher filter", :event => event.to_hash)
    @localDebug && (puts "LD> Running event_dispatcher filter, event: #{event.to_hash}")

    @filter.filter(event)
    filter_matched(event)
    @logger.debug? && @logger.debug("Event after event_dispatcher filter", :event => event.to_hash)
    @localDebug && (puts "LD> Event after event_dispatcher filte, event: #{event.to_hash}")
  end

end

class Filter_part
  def initialize(part_json, config)
    @event_filter_tags_to_process = part_json["event_filter_tags_to_process"]
    @set_event_filter_done_if_executed = part_json["set_event_filter_done_if_executed"] || false
    @config = config
  end

  def Filter_part.new_part(part_json, config)
    type = part_json['type']
    if type == "plugin"
      return Plugin.new(part_json, config)
    elsif type == "filter"
      return Filter.new(part_json, config)
    end
    nil
  end
end

class Plugin < Filter_part
  def initialize(part_json, config)
    super(part_json, config)
    p = part_json
    name = p["name"]
    path = p["require_path"].nil? ? "logstash/filters/#{name}" : p["require_path"]
    require path
    @plugin = LogStash::Plugin.lookup("filter", name).new(p["options"])
    @plugin.register
  end

  public

  def filter(event)
    if not @event_filter_tags_to_process.nil?
      event_filter_tag = event.get(@config["event_filter_tag_field"])
      if not @event_filter_tags_to_process.include?(event_filter_tag)
        return false
      end
    end
    @plugin.filter(event)
    return @set_event_filter_done_if_executed
  end
end

class Filter < Filter_part
  def initialize(part_json, config)
    super(part_json, config)
    @filter_parts = []
    part_json["filter_parts"].each do |p|
      @filter_parts << Filter_part.new_part(p, config)
    end
  end

  public

  def filter(event)
    @filter_parts.each do |p|
      if p.filter(event)
        return
      end
    end
  end
end
