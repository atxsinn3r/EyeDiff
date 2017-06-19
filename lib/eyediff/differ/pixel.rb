require 'eyediff/env'
require 'eyediff/logger'
require 'chunky_png'
include ChunkyPNG::Color

module EyeDiff::Differ
  class Pixel
    def initialize(image1, image2)
      @images = [ image1, image2 ]
    end

    def find_difference
      smart_resize!
      diff = []

      @images.first.height.times do |y|
        @images.first.row(y).each_with_index do |pixel, x|
          unless pixel == @images.last[x,y]
            score = Math.sqrt(
              (r(@images.last[x,y]) - r(pixel)) ** 2 +
              (g(@images.last[x,y]) - g(pixel)) ** 2 +
              (b(@images.last[x,y]) - b(pixel)) ** 2
            ) / Math.sqrt(MAX ** 2 * 3)

            diff << score
          end
        end
      end

      {
        total_pixels: @images.first.pixels.length,
        pixels_changed: diff.length,
        diff_percentage: (diff.inject {|sum, value| sum + value}.to_f / @images.first.pixels.length) * 100
      }
    end

    def generate_diff
      smart_resize!

      @images.first.height.times do |y|
        @images.first.row(y).each_with_index do |pixel, x|
          @images.last[x,y] = rgb(
            r(pixel) + r(@images.last[x,y]) - 2 * [r(pixel), r(@images.last[x,y])].min,
            g(pixel) + g(@images.last[x,y]) - 2 * [g(pixel), g(@images.last[x,y])].min,
            b(pixel) + b(@images.last[x,y]) - 2 * [b(pixel), b(@images.last[x,y])].min
          )
        end
      end

      @images.last
    end

    def same?
      results = find_difference
      EyeDiff::Logger.log("Pixel difference: #{results[:diff_percentage]}%")
      if results[:diff_percentage] < EyeDiff::Env.default_acceptable_difference
        return true
      end

      false
    end

    private

    def get_smallest_image_index
      image1_size = @images.first.width * @images.first.height
      image2_size = @images[1].width * @images[1].height

      if image1_size > image2_size
        1
      elsif image1_size < image2_size
        0
      else
        -1
      end
    end

    def smart_resize!
      small_image_index = get_smallest_image_index
      case small_image_index
      when 0
        @images[1] = @images[1].resize(@images[0].width, @images[0].height)
      when 1
        @images[0] = @images[0].resize(@images[1].width, @images[1].height)
      end
    end
  end
end
