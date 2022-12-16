# encoding: utf-8
require 'spec_helper'
require "logstash/filters/event_dispatcher"
require "insist"

describe LogStash::Filters::Event_dispatcher do
  describe "case_3: nested filter paths" do
    let(:config) do <<-CONFIG
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
