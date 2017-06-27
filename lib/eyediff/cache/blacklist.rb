require 'eyediff/env'

module EyeDiff
  module Cache
    module BlackList

      BLACKLIST = Env.blacklist_file_location

      def black_list
        @black_list ||= []
      end

      def add_to_blacklist(image_data)
        md5 = Helper::Converter.to_md5(image_data)
        add_md5_to_blacklist(md5)
      end

      def add_md5_to_blacklist(md5)
        @black_list << md5
      end

      def is_md5_in_blacklist?(md5)
        @black_list.include?(md5)
      end

      def is_in_blacklist?(image_data)
        md5 = Helper::Converter.to_md5(image_data)
        is_md5_in_blacklist?(md5)
      end

      def clear_blacklist
        @black_list = []
      end

      def has_blacklist?
        File.exists?(BLACKLIST)
      end

      def save_blacklist_to_file
        data = Marshal.dump(@black_list)
        File.open(BLACKLIST, 'wb') do |f|
          f.write(data)
        end
      end

      def load_blacklist_from_file
        File.open(BLACKLIST, 'rb') do |f|
          @black_list = Marshal.load(f.read)
        end
      end

    end
  end
end
