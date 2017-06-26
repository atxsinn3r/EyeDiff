require 'eyediff/env'
require 'mini_magick'

module EyeDiff::Differ
  class Pixel

    class Error < RuntimeError; end

    def initialize(image1, image2)
      @images = [ image1, image2 ].map { |i| MiniMagick::Image.read(i) }
      @diff  = []
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

      img1_pixels_width = 0
      img1_pixels_height = img1_pixels.length
      img1_pixels_height.times do |y|
        img1_pixels_width = img1_pixels[y].length
        img1_pixels_width.times do |x|
          next unless img2_pixels[y]
          next unless img2_pixels[y][x]
          next if img1_pixels[y][x] == img2_pixels[y][x]
          next if img1_pixels[y][x].length != 3 || img2_pixels[y][x].length != 3
          img1_rgb << rgb_to_int(img1_pixels[y][x])
          img2_rgb << rgb_to_int(img2_pixels[y][x])
          cal_cie76(img1_pixels[y][x], img2_pixels[y][x])
        end
      end

      # It turns out that the total pixels count doesn't actually indicate the number of
      # pixels x & y, therefore the result may be higher than 100%
      total_pixels = img1_pixels_width * img1_pixels_height
      pix_diff = @diff.inject { |sum,val| sum + val}.to_f / total_pixels * 100
      hist_diff = histogram_similar?(img1_rgb, img2_rgb)

      Helper::Output.print_status("Pixel difference: #{pix_diff}%")

      {
        pixel:  pix_diff,
        histogram: hist_diff
      }
    end

    def rgb_to_int(pixel)
      r, g, b = pixel
      (0xFFFF * r + 0xFF * g + b)
    end

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

    def histogram_similar?(img1_rgb, img2_rgb)
      match_count = 0
      begin
        img1_histogram = Hash[*img1_rgb.group_by{ |v| v }.flat_map{ |k, v| [k, v.size] }]
        img2_histogram = Hash[*img2_rgb.group_by{ |v| v }.flat_map{ |k, v| [k, v.size] }]
      rescue SystemStackError => e
        return true # Return true so we rely on cal_cie76 to figure out
      end
      img1_histogram.each do |rgb_val, count|
        percent = img2_histogram[rgb_val].to_f / count.to_f * 100
        match_count += 1 if percent <= EyeDiff::Env.default_acceptable_histogram_difference[:high] &&
                            percent >= EyeDiff::Env.default_acceptable_histogram_difference[:low]
      end

      diff = match_count.to_f / img1_histogram.length.to_f * 100
      Helper::Output.print_status("Histogram difference: #{diff}%")
      diff > 6.0 ? true : false
    end

    def similar?
      results = find_difference
      pix_diff = results[:pixel]
      hist_diff = results[:histogram]
      if pix_diff == 0.0 || pix_diff <= EyeDiff::Env.default_acceptable_pixel_difference && hist_diff == true
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
      @images.each do |img|
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
