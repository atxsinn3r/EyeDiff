#!/usr/bin/env ruby

lib = File.expand_path(File.join(__FILE__, '..', '..','lib'))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'eyediff'
require 'chunky_png'
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

    @cache = EyeDiff::Cache.new

    begin
      EyeDiff::Logger.log("Identifying image...")
      name = md5_match(image_data) || pixel_match(image_data)
      if name
        @cache.increase_popularity(name)
        EyeDiff::Logger.log("#{File.basename(options[:image_path])} is #{name}!")
        EyeDiff::Report.print_notes(name)
        return
      else
        EyeDiff::Logger.log('No match found.')
      end
    ensure
      @cache.close
    end
  end

  def md5_match(image)
    @cache.each do |name, data|
      data[:images].each do |ref|
        diff = EyeDiff::Differ::MD5.new(image, ref[:md5])
        return name if diff.same?
      end
    end

    nil
  end

  def pixel_match(image)
    image = ChunkyPNG::Image.from_string(image)
    @cache.each do |name, data|
      data[:images].each do |ref|
        diff = EyeDiff::Differ::Pixel.new(image, ref[:png])
        return name if diff.same?
      end
    end

    nil
  end

end

if __FILE__ == $PROGRAM_NAME
  i = IdImage.new
  i.run
end

