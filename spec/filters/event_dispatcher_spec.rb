# encoding: utf-8
require 'spec_helper'
require "logstash/filters/event_dispatcher"
require "insist"

describe LogStash::Filters::Event_dispatcher do
  describe "case_1: event_filter_tag already set in event" do
    let(:config) do
      <<-CONFIG
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

  describe "case_2: event_filter_tag set by ruby plugin" do
    let(:config) do
      <<-CONFIG
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

  describe "case_3: nested filter paths" do
    let(:config) do
      <<-CONFIG
      filter {
        event_dispatcher {
            config_dir => "#{File.dirname(__FILE__)}/case_3"
            # localDebug => true
        }
      }
      CONFIG
    end

    sample 'level_1_tag=csv,event_log=1,2019-08-29T01:53:12Z,Amex,Giovanna Van der Linde,Female,185.216.194.245,Industrial,Philippines,55' do
      insist { subject.get("id") } == "1"
      insist { subject.get("timestamp") } == "2019-08-29T01:53:12Z"
      insist { subject.get("ip_address") } == "185.216.194.245"
    end

    sample 'level_1_tag=kv,event_log=a:1 b:2 c:3' do
      insist { subject.get("a") } == "1"
      insist { subject.get("b") } == "2"
      insist { subject.get("c") } == "3"
    end

    sample 'level_1_tag=filter_1,event_log=level_1x_tag=filter_11,event_log=(kv=)a=1,b=2,c=3,d=4,e=5' do
      insist { subject.get("a") } == "1"
      insist { subject.get("b") } == "2"
      insist { subject.get("c") } == "3"
    end

    sample 'level_1_tag=filter_1,event_log=level_1x_tag=filter_11,event_log=(json){"Property 1":"value x","Property 2":"value y"}' do
      insist { subject.get("Property 1") } == "value x"
      insist { subject.get("Property 2") } == "value y"
    end

    sample 'level_1_tag=filter_1,event_log=level_1x_tag=filter_11,event_log=(kv|)a|1,b|2,c|3,d|4,e|5' do
      insist { subject.get("a") } == "1"
      insist { subject.get("b") } == "2"
      insist { subject.get("c") } == "3"
    end

    sample 'level_1_tag=filter_1,event_log=level_1x_tag=filter_11,event_log=(kv%)a%1,b%2,c%3,d%4,e%5' do
      insist { subject.get("a") } == "1"
      insist { subject.get("b") } == "2"
      insist { subject.get("c") } == "3"
    end

  end
end
