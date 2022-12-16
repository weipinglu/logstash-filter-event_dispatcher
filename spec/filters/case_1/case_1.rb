# encoding: utf-8
require 'spec_helper'
require "logstash/filters/event_dispatcher"
require "insist"

describe LogStash::Filters::Event_dispatcher do
  describe "case_1: event_filter_tag already set in event" do
    let(:config) do <<-CONFIG
      filter {
        json {
            source => "message"
        }
      }
      filter {
        event_dispatcher {
            config_dir => "#{File.dirname(__FILE__)}/case_1"
        }
      }
    CONFIG
    end

    sample '{ "event_filter_tag": "csv_logs", "message": "4,2018-07-05T22:58:10Z,Mastercard,Mike Smith,Male,196.160.55.191,Food,USA,32" }' do
      insist { subject.get("id") } == "4"
      insist { subject.get("timestamp") } == "2018-07-05T22:58:10Z"
      insist { subject.get("ip_address") } == "196.160.55.191"
      insist { subject.get("age") } == "32"
    end

    sample '{ "event_filter_tag": "json_logs", "message": "{\"Property 1\":\"value x\",\"Property 2\":\"value y\"}" }' do
      insist { subject.get("Property 1") } == "value x"
      insist { subject.get("Property 2") } == "value y"
    end

  end
end
