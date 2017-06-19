#!/usr/bin/env ruby

lib = File.expand_path(File.join(__FILE__, '..', '..', 'lib'))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'eyediff'
require 'chunky_png'

class GenerateDiff
  def self.help
    puts "Usage: #{__FILE__} Image1 Image2"
    exit
  end

  def self.run
    if ARGV.length != 2 || ARGV =~ /^\-h/i
      help
    end

    name1 = ARGV.shift
    name2 = ARGV.shift
    image1 = ChunkyPNG::Image.from_file(name1)
    image2 = ChunkyPNG::Image.from_file(name2)
    diff = EyeDiff::Differ.new(image1, image2)
    diff_image = diff.generate_diff
    diff_image.save('diff.png')
    EyeDiff::Logger.log('Saved as diff.png')
  end
end

if __FILE__ == $PROGRAM_NAME
  GenerateDiff.run
end

