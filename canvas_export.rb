#!/usr/bin/ruby

dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'httparty'
require 'pp'
require 'json'
require 'reverse_markdown'

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
                per_page: 1
              },
              headers: {
                'Authorization' => "Bearer #{mitie_api_key}"
                }
              )

topics.each_with_index do |topic, index|
  encoded_posts_url = URI.encode("#{mitie_uri}/#{topic['id']}/entries.json")

  discourse_topic = HTTParty.post(discourse_uri.to_str,
                body: {
                  title: "#{topic['title']}_#{index}",
                  category: 5,
                  raw: topic['message'],
                  created_at: topic['posted_at'],
                  cook_method: 2,
                  skip_validations: true,
                  is_warning: false
                }.to_json,
                headers: {
                  'Content-Type' => discourse_content_type
                  }
                )

  puts "Topic is ok: #{discourse_topic.ok?}"

  posts = HTTParty.get(encoded_posts_url,
                headers: {
                  'Authorization' => "Bearer #{mitie_api_key}"
                  }
                )

  posts.each do |post|
    # puts post['id']
    # puts "=============="
    # puts post['user_name']
    # puts ""
    # message = post['message'].to_json
    message = "Some content that is not from the canvas API scrape"

    puts message

    discourse_post = HTTParty.post(discourse_uri.to_str,
                  body: {
                    topic_id: discourse_topic['id'],
                    raw: message,
                    cook_method: 2,
                    created_at: post['created_at'],
                    archetype: 'regular'
                  }.to_json,
                  headers: {
                    'Content-Type' => discourse_content_type
                    }
                  )
    puts "Post is ok: #{discourse_post.ok?}"
    puts discourse_post.response.message
  end
end

# puts response.methods
# puts ""
# puts topics.headers
