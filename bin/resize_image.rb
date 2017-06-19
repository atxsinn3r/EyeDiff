#!/usr/bin/env ruby

require 'optparse'
require 'chunky_png'

class ImageResizer
  def self.get_options
    options = {}

    parser = OptionParser.new do |opt|
      opt.banner = "Usage: #{__FILE__} [options]"
      opt.separator ''
      opt.separator 'Specific options:'

      opt.on('-i', '--image <String>', 'The image to resize') do |v|
        options[:image_path] = v
      end

      opt.on('-h', '--height <Fixnum>', 'Desired image height') do |v|
        options[:height] = v
      end

      opt.on('-w', '--width <Fixnum>', 'Desired image width') do |v|
        options[:width] = v
      end

      opt.on_tail('-h', '--help', 'Show this message') do
        puts opt
        exit
      end
    end

    parser.parse!(ARGV)

    options
  end

  def self.run
    options = get_options
    puts '[*] Loading image...'
    img = ChunkyPNG::Image.from_file(options[:image_path])
    puts "[*] Resizing image to #{options[:height]}x#{options[:width]}"
    new_image = img.resize(options[:width], options[:height])
    puts "[*] Rewriting image...."
    new_image.save(options[:image_path])
    puts "[*] Image rewritten."
  end
end

if __FILE__ == $PROGRAM_NAME
  ImageResizer.run
end
