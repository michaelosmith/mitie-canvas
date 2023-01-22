require 'open-uri'

module DiscourseImport
  module Helper
    extend self

    def get_mime_type(file)
      `file -Ib #{file}`.gsub(/\n/,"").split(';').first
    end

    def download_file(url, name)
      path = File.expand_path File.dirname(__FILE__)
      file = open(url)
      downloaded_file = IO.copy_stream(file, "#{path}/#{name}")
      mime_type = get_mime_type("#{path}/#{name}")
      return Faraday::UploadIO.new("#{path}/#{name}", mime_type)
    end

    def download_embedded_file(url, name)
      path = File.expand_path File.dirname(__FILE__)
      file = open(url)
      downloaded_file = IO.copy_stream(file, "#{path}/#{name}")
      mime_type = get_mime_type("#{path}/#{name}")
      extension = mime_type.split('/')[1]
      file_rename = File.rename("#{path}/#{name}","#{path}/#{name}.#{extension}")
      return Faraday::UploadIO.new("#{path}/#{name}.#{extension}", mime_type)
    end

    def get_id_from_url(url)
      url[/\d+/]
    end

    def get_id_from_embedded_url(url)
      url.match(/\d+$/)[0]
    end

    def cleanup_embedded_urls(array)
      array.delete_if {|x| /@/.match(x) }
      array.delete_if {|x| /preview/.match(x) }
      return array
    end

    def start_timer
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def end_timer
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def flatten_array(arr)
      results = []
      arr.each do |a|
        results << a
        if a['recent_replies']
          a['recent_replies'].each do |b|
            results << b
          end
        end
      end
      results = results.sort_by { |c| c['updated_at'] }
      return results
    end

    def api_call(api, type, *args)
      discourse = api
      wait_seconds = 45
      begin
      case type
      when 'upload_file'
        discourse.upload_file(file: args[0])
      when 'create_topic'
        discourse.create_topic(
          category: 5,
          skip_validations: true,
          auto_track: false,
          created_at: args[0],
          title: args[1],
          raw: args[2]
        )
      when 'create_post'
        discourse.create_post(
          topic_id: args[0],
          raw: args[1],
          created_at: args[2]
        )
      when 'change_topic_status'
        discourse.change_topic_status(args[0],args[1],args[2])
      end
      rescue DiscourseApi::TooManyRequests => err
        puts "Waiting #{wait_seconds} for API to become available again..."
        sleep wait_seconds.to_i
        retry
      rescue
        puts "Something else went wrong...."
        puts $!.message
        sleep wait_seconds.to_i
        retry
      end
    end

  end
end

class String
  def black; "\e[30m#{self}\e[0m" end
  def red; "\e[31m#{self}\e[0m" end
  def green; "\e[32m#{self}\e[0m" end
  def brown; "\e[33m#{self}\e[0m" end
  def blue; "\e[34m#{self}\e[0m" end
  def magenta; "\e[35m#{self}\e[0m" end
  def cyan; "\e[36m#{self}\e[0m" end
  def gray; "\e[37m#{self}\e[0m" end

  def bg_black; "\e[40m#{self}\e[0m" end
  def bg_red; "\e[41m#{self}\e[0m" end
  def bg_green; "\e[42m#{self}\e[0m" end
  def bg_brown; "\e[43m#{self}\e[0m" end
  def bg_blue; "\e[44m#{self}\e[0m" end
  def bg_magenta; "\e[45m#{self}\e[0m" end
  def bg_cyan; "\e[46m#{self}\e[0m" end
  def bg_gray; "\e[47m#{self}\e[0m" end

  def bold; "\e[1m#{self}\e[22m" end
  def italic; "\e[3m#{self}\e[23m" end
  def underline; "\e[4m#{self}\e[24m" end
  def blink; "\e[5m#{self}\e[25m" end
  def reverse_color; "\e[7m#{self}\e[27m" end
end
