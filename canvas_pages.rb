#!/usr/bin/ruby
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
# script_dir = File.expand_path(File.dirname(__FILE__))
require 'httparty'
require 'pp'
require 'json'
require 'open-uri'

# Mitie site variables
mitie_api_key = '<api-key>'
mitie_course_id = '1'
mitie_uri = "https://mitie.instructure.com/api/v1/courses/#{mitie_course_id}/discussion_topics"

# Discourse site variables
discourse_api_key = '<api-key>'
discousre_api_username = 'user2'
discourse_uri = "http://127.0.0.1:4000/posts?api_key=#{discourse_api_key}&api_username=#{discousre_api_username}"
discourse_content_type = 'application/json'

topics = HTTParty.get(mitie_uri.to_str,
              body: {
                per_page: 100
              },
              headers: {
                'Authorization' => "Bearer #{mitie_api_key}"
                }
              )

p topics

next_page = topics.headers['Link'].split(/,/).detect{|rel| rel.match(/rel="next"/) }.split(/;/).first.strip[1..-2] rescue nil
puts next_page
puts "There is a next page" if next_page
