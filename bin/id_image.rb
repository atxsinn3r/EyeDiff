#!/usr/bin/env ruby

lib = File.expand_path(File.join(__FILE__, '..', '..','lib'))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'eyediff'
require 'helper'
require 'optparse'

class IdImage
  def get_options
    options = {}

    parser = OptionParser.new do |opt|
      opt.banner = "Usage: #{__FILE__} [options]"
      opt.separator ''
      opt.separator 'Specific options:'

      opt.on('-i', '--image <String>', 'The image to look up') do |v|
        options[:image_path] = v
      end

      opt.on('-s', '--size <String>', 'Max number of objects to keep in the cache. Default: 3') do |v|
        options[:cache_size] = v
      end

      opt.on_tail('-h', '--help', 'Show this message') do
        puts opt
        exit
      end
    end

    parser.parse!(ARGV)

    options
  end

  def run
    options = get_options
    image_data = File.read(options[:image_path])

    if image_data.empty?
      Helper::OUtput.print_error('This file is empty')
      return
    end

    @cache = EyeDiff::Cache.new

    begin
      Helper::Output.print_status("Identifying image...")
      name = md5_match(image_data) || pixel_match(image_data)
      if name
        @cache.increase_popularity(name)
        Helper::Output.print_status("#{File.basename(options[:image_path])} is #{name}!")
        return
      else
        Helper::Output.print_status('No match found.')
      end
    ensure
      @cache.close
    end
  end

  def md5_match(image_data)
    @cache.each do |ref_name, refs|
      refs.each do |ref|
        md5 = ref[:md5]
        diff = EyeDiff::Differ::MD5.new(image_data, md5)
        return ref_name if diff.same?
      end
    end

    nil
  end

  def pixel_match(image)
    @cache.each do |ref_name, refs|
      begin
        refs.each do |ref|
          ref_data = File.read(ref[:path])
          diff = EyeDiff::Differ::Pixel.new(image, ref_data)
          return ref_name if diff.similar?
        end
      rescue EyeDiff::Differ::Pixel::Error => e
        Helper::Output.print_error(e.message)
        break
      end
    end

    nil
  end

end

if __FILE__ == $PROGRAM_NAME
  i = IdImage.new
  i.run
end

