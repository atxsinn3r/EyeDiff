require 'eyediff/env'
require 'helper'
require 'eyediff/references'

module EyeDiff

  class Cache < References

    CACHEFILE = Env.cache_file_location
    BLACKLIST = Env.blacklist_file_location
    IMAGESDIR = Env.reference_directory

    def initialize
      @cache = {}
      @black_list = []

      load_cache_from_file if has_cache_file?
      load_blacklist_from_file if has_blacklist?
      update_cache_from_database
    end

    def update_cache_from_database
      Helper::Output.print_status('Updating cache...')

      References.each do |ref_name, ref_paths|
        if !@cache.has_key?(ref_name)
          add(name: ref_name, paths: ref_paths)
        elsif @cache.has_key?(ref_name) && ref_paths.length > @cache[ref_name][:references].length
          add(name: ref_name, paths: ref_paths)
        end
      end
    end

    def add(opts)
      images = opts[:paths].collect { |path|
        {
          path: path,
          md5: Helper::Converter.file_to_md5(path)
        }
      }
      @cache[opts[:name]] = { references: images, popularity: 0 }
      Helper::Output.print_status("Added new item to cache: #{opts[:name]}")

      clear_blacklist unless @black_list.empty?

      sort
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
      Helper::Output.print_status('Cleared black list')
    end

    def sort_by_availability
      @cache = @cache.sort_by { |k,v| (v[:references].empty?) ? 1 : 0 }.to_h
      nil
    end

    def sort_by_popularity
      @cache = @cache.sort_by { |k, data| -data[:popularity] }.to_h
      nil
    end

    def sort
      sort_by_popularity
      sort_by_availability
      nil
    end

    def increase_popularity(name)
      return unless @cache.has_key?(name)
      Helper::Output.print_status("Increasing #{name} popularity by 1")
      @cache[name][:popularity] += 1
      sort
    end

    def each
      @cache.each_pair do |ref_name, val|
        yield ref_name, val[:references]
      end
    end

    def save_cache_to_file
      Helper::Output.print_status('Saving cache to file...')
      data = Marshal.dump(@cache)
      File.open(CACHEFILE, 'wb') do |f|
        f.write(data)
        Helper::Output.print_status('Cache saved')
      end
    end

    def save_blacklist_to_file
      Helper::Output.print_status('Saving blacklist to file...')
      data = Marshal.dump(@black_list)
      File.open(BLACKLIST, 'wb') do |f|
        f.write(data)
        Helper::Output.print_status('Blacklist saved')
      end
    end

    def close
      EyeDiff::Report.print_popularity(@cache)
      save_cache_to_file
      save_blacklist_to_file
    end

    def has_cache_file?
      File.exists?(CACHEFILE)
    end

    def has_blacklist?
      File.exists?(BLACKLIST)
    end

    def load_blacklist_from_file
      Helper::Output.print_status('Loading blacklist from file')
      File.open(BLACKLIST, 'rb') do |f|
        @black_list = Marshal.load(f.read)
        Helper::Output.print_status('Loaded blacklist from file')
      end
    end

    def load_cache_from_file
      Helper::Output.print_status('Loading cache from file')
      File.open(CACHEFILE, 'rb') do |f|
        @cache = Marshal.load(f.read)
        Helper::Output.print_status('Loaded cache from file')
      end
    end

  end
end
