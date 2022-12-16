# encoding: utf-8
require 'spec_helper'
require "logstash/filters/event_dispatcher"
require "insist"

describe LogStash::Filters::Event_dispatcher do
  describe "case_2: event_filter_tag set by ruby plugin" do
    let(:config) do <<-CONFIG
      filter {
        event_dispatcher {
            config_dir => "#{File.dirname(__FILE__)}/case_2"
        }
      }
    CONFIG
    end

    sample '4,2018-07-05T22:58:10Z,Mastercard,Mike Smith,Male,196.160.55.191,Food,USA,32' do
      insist { subject.get("id") } == "4"
      insist { subject.get("timestamp") } == "2018-07-05T22:58:10Z"
      insist { subject.get("ip_address") } == "196.160.55.191"
      insist { subject.get("age") } == "32"
    end

    sample '{"Property 1": "value x",  "Property 2": "value y"}' do
      insist { subject.get("Property 1") } == "value x"
      insist { subject.get("Property 2") } == "value y"
    end

  end
end
