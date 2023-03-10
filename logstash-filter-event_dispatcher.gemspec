Gem::Specification.new do |s|
  s.name = 'logstash-filter-event_dispatcher'
  s.version         = '0.1.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = "This example filter replaces the contents of the message field with the specified value."
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Elastic"]
  s.email = 'info@elastic.co'
  s.homepage = "http://www.elastic.co/guide/en/logstash/current/index.html"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api"
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'logstash-filter-csv'
  s.add_development_dependency 'logstash-filter-json'
  s.add_development_dependency 'logstash-filter-ruby'
  s.add_development_dependency 'logstash-filter-kv'
  s.add_development_dependency 'insist'
end
