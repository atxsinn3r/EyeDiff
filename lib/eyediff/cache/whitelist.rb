require 'eyediff/env'
require 'helper'

module EyeDiff
  module Cache
    module WhiteList

      WHITELIST = EyeDiff::Env.whitelist_file_location

      def white_list
        @white_list ||= {}
      end

      def add_to_whitelist(name, image_data)
        md5 = Helper::Converter.to_md5(image_data)
        add_md5_to_whitelist(name, md5)
      end

      def add_md5_to_whitelist(name, md5)
        if white_list[name]
          white_list[name] << md5
        else
          white_list[name] = [ md5 ]
        end
      end

      def get_name_in_whitelist_by_md5(md5)
        white_list.each_pair do |name, md5_list|
          return name if md5_list.include?(md5)
        end

        nil
      end

      def get_name_in_whitelist_by_data(image_data)
        md5 = Helper::Converter.to_md5(image_data)
        get_name_in_whitelist_by_md5(md5)
      end

      def clear_whitelist
        @white_list = {}
      end

      def has_whitelist?
        File.exists?(WHITELIST)
      end

      def save_whitelist_to_file
        data = Marshal.dump(@white_list)
        File.open(WHITELIST, 'wb') do |f|
          f.write(data)
        end
      end

      def load_whitelist_from_file
        File.open(WHITELIST, 'rb') do |f|
          @white_list = Marshal.load(f.read)
        end
      end

    end
  end
end
