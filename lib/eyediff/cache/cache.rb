require 'eyediff/env'
require 'helper'
require 'eyediff/cache/references'
require 'eyediff/cache/blacklist'
require 'eyediff/cache/whitelist'

module EyeDiff::Cache

  class Cache < References

    include BlackList
    include WhiteList

    CACHEFILE = EyeDiff::Env.cache_file_location
    IMAGESDIR = EyeDiff::Env.reference_directory

    def initialize
      @cache = {}

      load_cache_from_file if has_cache_file?
      load_blacklist_from_file if has_blacklist?
      load_whitelist_from_file if has_whitelist?
      update_cache_from_references
    end

    def update_cache_from_references
      Helper::Output.print_status('Updating cache from references...')

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

      clear_blacklist unless black_list.empty?

      sort
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
      data = Marshal.dump(@cache)
      File.open(CACHEFILE, 'wb') do |f|
        f.write(data)
      end
    end

    def has_cache_file?
      File.exists?(CACHEFILE)
    end

    def close
      EyeDiff::Report.print_popularity(@cache)
      save_cache_to_file
      save_blacklist_to_file
      save_whitelist_to_file
    end

    def load_cache_from_file
      File.open(CACHEFILE, 'rb') do |f|
        @cache = Marshal.load(f.read)
      end
    end

  end
end
