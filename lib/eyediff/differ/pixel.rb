require 'eyediff/env'
require 'mini_magick'

# For performance reasons, we don't want to run #each_slice and #to_a.
module MiniMagick
  class Image
    def get_pixels(*args)
      convert = MiniMagick::Tool::Convert.new
      if args.any?
        raise ArgumentError, "must provide 4 arguments: (x, y, columns, rows)" if args.size != 4
        x, y, columns, rows = args
        convert << "#{path}[#{rows}x#{columns}+#{x}+#{y}]"
      else
        columns = width
        convert << path
      end

      convert.depth(8)
      convert << "RGB:-"
      content = convert.call
      convert.clear

      content.unpack("C*")
    end
  end
end


module EyeDiff::Differ
  class Pixel

    class Error < RuntimeError; end

    def initialize(image1, image2)
      @images = [ image1, image2 ].map { |i| MiniMagick::Image.read(i) }
      @diff  = []
      @default_acceptable_pixel_difference = EyeDiff::Env.default_acceptable_pixel_difference
    end

    def find_difference
      if is_image_too_small?(@images.first) || is_image_too_small?(@images.last)
        raise EyeDiff::Differ::Pixel::Error, 'One of the images is too skinny. Not enough information to process.'
      end

      normalize_images!
      img1 = @images.first
      img2 = @images.last
      img1_pixels = img1.get_pixels
      img2_pixels = img2.get_pixels

      if img1_pixels.empty?
        raise EyeDiff::Differ::Pixel::Error, 'Unable to get pixels for imag1'
      elsif img2_pixels.empty?
        raise EyeDiff::Differ::Pixel::Error, 'Unable to get pixels for image2'
      end

      img1_rgb = []
      img2_rgb = []

      (0..img1_pixels.length).step(3) do |i|
        rgb1 = img1_pixels[i, 3]
        rgb2 = img2_pixels[i, 3]
        break unless rgb2
        next if rgb1 == rgb2
        next if rgb1.length != 3 || rgb2.length != 3
        img1_rgb << rgb_to_int(rgb1)
        img2_rgb << rgb_to_int(rgb2)
        cal_cie76(rgb1, rgb2)
      end

      total_pixels = img1_pixels.length
      pix_diff = @diff.inject { |sum,val| sum + val}.to_f / total_pixels * 100
      dominance = dominance_similar?(img1_rgb, img2_rgb)

      Helper::Output.print_status("Pixel difference: #{pix_diff}%")

      {
        pixel:  pix_diff,
        dominance: dominance
      }
    end

    def rgb_to_int(pixel)
      r, g, b = pixel
      (0xFFFF * r + 0xFF * g + b)
    end

    # @see https://en.wikipedia.org/wiki/Color_difference
    def cal_cie76(img1_pixels, img2_pixels)
      r1, g1, b1 = img1_pixels
      r2, g2, b2 = img2_pixels
      score = Math.sqrt(
        (r2 - r1) ** 2 +
        (g2 - g1) ** 2 +
        (b2 - b1) ** 2
      ) / Math.sqrt(255 ** 2 * 3)
      @diff << score
    end

    # Compare dominance with histograms
    def dominance_similar?(img1_rgb, img2_rgb)
      match_count = 0
      begin
        img1_histogram = Hash[*img1_rgb.group_by{ |v| v }.flat_map{ |k, v| [k, v.size] }]
        img2_histogram = Hash[*img2_rgb.group_by{ |v| v }.flat_map{ |k, v| [k, v.size] }]
      rescue SystemStackError => e
        # Return true so we rely on cal_cie76 to figure out with a lower acceptable level
        @default_acceptable_pixel_difference -= 1
        return true
      end

      # Filter out the colors that are nowhere near the most dominant color.
      # This will also filter out pixels that we can barely see.
      dominant_color_value = img1_histogram[img1_histogram.keys.first]
      low_range = dominant_color_value - dominant_color_value * 0.99
      high_range = dominant_color_value + dominant_color_value * 0.3
      img1_histogram = img1_histogram.select { |k, v| v.between?(0, high_range) }
      img2_histogram = img2_histogram.select { |k, v| v.between?(0, high_range) }

      img1_histogram.each do |rgb_val, count|
        percent = img2_histogram[rgb_val].to_f / count.to_f * 100
        if percent.between?(EyeDiff::Env.default_acceptable_histogram_difference[:low], EyeDiff::Env.default_acceptable_histogram_difference[:high])
          match_count += 1
        end
      end

      sim = match_count.to_f / img1_histogram.length * 100
      Helper::Output.print_status("Histogram similarity: #{sim}%")
      sim > 6.5 ? true : false
    end

    def similar?
      results = find_difference
      pix_diff = results[:pixel]
      dominance_match = results[:dominance]
      if pix_diff == 0.0 || pix_diff <= @default_acceptable_pixel_difference && dominance_match == true
        true
      else
        false
      end
    end

    def is_image_too_small?(img)
      percent = 0
      if img.height > img.width
        percent = img.width.to_f / img.height.to_f * 100
      elsif img.width > img.height
        percent = img.height.to_f / img.width.to_f * 100
      elsif img.width == img.height && img.height < 100
        return true
      end

      return true if percent < 10

      false
    end

    def normalize_images!
      smallest_width, smallest_height = get_smallest_image_size
      @images.map do |img|
        img.resize("#{smallest_width}x#{smallest_height}!")
      end
    end

    def get_smallest_image_size
      image1_size = @images.first.width * @images.first.height
      image2_size = @images.last.width * @images.last.height

      if image1_size > image2_size
        [ @images.last.width, @images.last.height ]
      else
        [ @images.first.width, @images.first.height ]
      end
    end

  end
end
