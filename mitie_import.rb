#!/usr/bin/ruby

require 'pandarus'
require 'discourse_api'
require 'reverse_markdown'
require 'nokogiri'
require_relative 'mitie_import_helpers'

# Canvas site variables
api_key = '<api-key>'
canvas_course_id = '1'
canvas_uri = "https://mitie.instructure.com/api"
canvas = Pandarus::Client.new(prefix: canvas_uri,token: api_key)

# Discourse site variables
discourse_url = 'http://timemachine.mitie.edu.au'
discourse = DiscourseApi::Client.new(discourse_url)
discourse.api_key = '<api-key>'
discourse.api_username = "michael.smith"

# get some timing stats
script_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# Get Canvas topics from course ID 1
canvas_topics = canvas.list_discussion_topics_courses(canvas_course_id)

# Loop through each topic
canvas_topics.each do |canvas_topic|

  # Check to see if there are any embedded files in message
  # embedded_files = URI.extract(canvas_topic[:message])
  embedded_files = Nokogiri::HTML.parse canvas_topic['message']
  embedded_files = embedded_files.search('img')

  unless embedded_files.nil? || embedded_files.empty?
    if embedded_files.css('[data-api-endpoint]').count > 0
      embedded_files.each do |embedded_file|
        embedded_file_id = DiscourseImport::Helper.get_id_from_embedded_url(embedded_file.attributes['data-api-endpoint'].value)
        embedded_file_public_url = canvas.get_public_inline_preview_url(embedded_file_id)
        downloaded_embedded_file = DiscourseImport::Helper.download_embedded_file(embedded_file_public_url['public_url'], embedded_file_id)

        discourse_upload = DiscourseImport::Helper.api_call(discourse, 'upload_file', downloaded_embedded_file)

        doc = Nokogiri::HTML.parse canvas_topic['message']
        embedded_file_edit = doc.css("[data-api-endpoint='#{embedded_file.attributes['data-api-endpoint'].value}']")
        embedded_file_edit[0].set_attribute('src', discourse_upload['url'])
        embedded_file_edit[0].remove_attribute('data-api-endpoint')
        embedded_file_edit[0].remove_attribute('data-api-returntype')
        canvas_topic['message'] = doc.to_html
        puts "Added embedded file to message."
      end
    end
  end

  # Convert html message to markdown (Discourse likes this format)
  canvas_topic_message = ReverseMarkdown.convert canvas_topic['message']
  canvas_topic_message = "**#{canvas_topic['user_name']}** said:\n\n #{canvas_topic_message}"

  # Check if there are attachments as part of the post
  unless canvas_topic['attachments'].nil? || canvas_topic['attachments'].empty?

    # Loop through each attachment
    canvas_topic['attachments'].each do |canvas_attachment|

      # Download file from canvas and upload to Discourse
      canvas_attachment_id = DiscourseImport::Helper.get_id_from_url(canvas_attachment['url'])
      canvas_attachment_public_url = canvas.get_public_inline_preview_url(canvas_attachment_id)
      downloaded_file = DiscourseImport::Helper.download_file(canvas_attachment_public_url['public_url'],canvas_attachment['filename'])

      discourse_upload = DiscourseImport::Helper.api_call(discourse, 'upload_file', downloaded_file)

      canvas_topic_message = "#{canvas_topic_message}\n\n[#{canvas_attachment['display_name']}](#{discourse_upload['url']})"

      puts "Added attachment: [#{canvas_attachment['display_name']}]".brown
    end
  end

  discourse_topic = DiscourseImport::Helper.api_call(discourse, 'create_topic', canvas_topic['posted_at'], canvas_topic['title'], canvas_topic_message)

  puts "Created topic: #{canvas_topic['title']} id: #{canvas_topic['id']}".green
  puts canvas_topic['attachments'] ? "Has: #{canvas_topic['attachments'].count} attachments".brown : "Has: zero attachments".brown

  canvas_topic_posts = canvas.list_topic_entries_courses(canvas_course_id,canvas_topic['id'])
  canvas_topic_posts = DiscourseImport::Helper.flatten_array(canvas_topic_posts)

  canvas_topic_posts.each do |canvas_post|

    embedded_files = Nokogiri::HTML.parse canvas_post['message']
    embedded_files = embedded_files.search('img')

    unless embedded_files.nil? || embedded_files.empty?
      if embedded_files.css('[data-api-endpoint]').count > 0
        embedded_files.each do |embedded_file|
          embedded_file_id = DiscourseImport::Helper.get_id_from_embedded_url(embedded_file.attributes['data-api-endpoint'].value)
          embedded_file_public_url = canvas.get_public_inline_preview_url(embedded_file_id)
          downloaded_embedded_file = DiscourseImport::Helper.download_embedded_file(embedded_file_public_url['public_url'], embedded_file_id)

          discourse_upload = DiscourseImport::Helper.api_call(discourse, 'upload_file', downloaded_embedded_file)

          doc = Nokogiri::HTML.parse canvas_post['message']
          embedded_file_edit = doc.css("[data-api-endpoint='#{embedded_file.attributes['data-api-endpoint'].value}']")
          embedded_file_edit[0].set_attribute('src', discourse_upload['url'])
          embedded_file_edit[0].remove_attribute('data-api-endpoint')
          embedded_file_edit[0].remove_attribute('data-api-returntype')
          canvas_post['message'] = doc.to_html
          puts "Added embedded file to message."
        end
      end
    end

    canvas_post_message = ReverseMarkdown.convert canvas_post['message']
    canvas_post_message = "**#{canvas_post['user_name']}** said:\n\n #{canvas_post_message}"

    unless canvas_post['attachments'].nil? || canvas_post['attachments'].empty?

      canvas_post['attachments'].each do |canvas_post_attachment|

        # Download file from canvas and upload to Discourse
        canvas_attachment_id = DiscourseImport::Helper.get_id_from_url(canvas_post_attachment['url'])
        canvas_attachment_public_url = canvas.get_public_inline_preview_url(canvas_attachment_id)
        downloaded_file = DiscourseImport::Helper.download_file(canvas_attachment_public_url['public_url'],canvas_post_attachment['filename'])

        discourse_upload = DiscourseImport::Helper.api_call(discourse, 'upload_file', downloaded_file)

        canvas_post_message = "#{canvas_post_message}\n\n[#{canvas_post_attachment['display_name']}](#{discourse_upload['url']})"

        puts "Added attachment: [#{canvas_post_attachment['display_name']}]".brown
      end
    end

    discourse_topic_post = DiscourseImport::Helper.api_call(discourse, 'create_post', discourse_topic['topic_id'], canvas_post_message, canvas_post['created_at'])

    puts "  Added thread by: #{canvas_post['user_name']}".cyan
    puts canvas_post['attachments'] ? "  Has: #{canvas_post['attachments'].count} attachments".brown : "  Has: zero attachments".brown

  end

  # Lock topic for editing
  discourse_topic_id    = discourse_topic['topic_id']
  discourse_topic_slug  = discourse_topic['topic_slug']
  params = { status: 'archived', enabled: true, api_username: 'michael.smith' }

  DiscourseImport::Helper.api_call(discourse, 'change_topic_status', discourse_topic_slug, discourse_topic_id, params)

end
script_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
script_elapsed = script_end - script_start
puts "\n\nTook #{script_elapsed} seconds to complete.".green
