require 'eyediff/env'
require 'eyediff/logger'
require 'eyediff/references'
require 'chunky_png'
require 'digest'

module EyeDiff

  class Cache < References

    DEFAULTMAXINITOBJECTS = 10
    CACHEFILE             = Env.cache_file_location
    IMAGESDIR             = Env.reference_directory

    def initialize(max_init_count=DEFAULTMAXINITOBJECTS)
      @max_init_count = max_init_count
      @cache = {}
      @changed = false

      if has_cache_file?
        load_cache_from_file
        update_cache_from_database
      else
        init_cache_from_database
      end
    end

    def max_init_count
      @max_init_count
    end

    def init_cache_from_database
      Logger.log('Loading images from database, this may take a while...')

      References.get_names.each do |name|
        add(name: name, image_paths: References.get_image_paths(name))
      end
    end

    def update_cache_from_database
      Logger.log('Looking for new images to add to cache...')

      References.get_names.each do |name|
        next if @cache.has_key?(name)
        add(name: name, image_paths: References.get_image_paths(name))
      end
    end

    def add(opts)
      @changed = true
      free_least_popular_object if init_count >= max_init_count
      images = opts[:image_paths].collect { |path|
        img_data = File.read(File.join(IMAGESDIR, path))
        {
          png: ChunkyPNG::Image.from_string(img_data),
          md5: Digest::MD5.hexdigest(img_data)
        }
      }
      @cache[opts[:name]] = { images: images, popularity: 0 }
      Logger.log("Added new item to cache: #{opts[:name]}")

      sort
    end

    def reinit(opts)
      @changed = true
      free_least_popular_object if init_count >= max_init_count
      images = opts[:image_paths].collect { |path|
        img_data = File.read(File.join(IMAGESDIR, path))
        {
          png: ChunkyPNG::Image.from_string(img_data),
          md5: Digest::MD5.hexdigest(img_data)
        }
      }
      @cache[opts[:name]] = { images: images, popularity: 0 }
      Logger.log("Reinitialized: #{opts[:name]}")
      sort
    end

    def free_least_popular_object
      @changed = true
      least_popular_object = @cache.select { |k, data| !data[:images].empty? }.keys.last
      @cache[least_popular_object][:images] = []
      Logger.log("Freed least popular #{least_popular_object}")

      nil
    end

    def init_count
      @cache.select { |k, data| !data[:images].empty? }.length
    end

    def sort_by_availability
      @cache = @cache.sort_by { |k,v| (v[:images].empty?) ? 1 : 0 }.to_h
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
      @changed = true
      Logger.log("Increasing #{name} popularity by 1")
      @cache[name][:popularity] += 1
      sort
    end

    def each
      @cache.each do |item|
        name = item[0]
        data = item[1]
        if data[:images].empty?
          reinit(name: name, image_paths: References.get_image_paths(name))
          yield [name, @cache[name]]
        else
          yield item
        end
      end
    end

    def size
      @cache.length
    end

    def cache_changed?
      @changed
    end

    def save_as_file
      Logger.log('Saving cache to file...')
      data = Marshal.dump(@cache)
      File.open(CACHEFILE, 'wb') do |f|
        f.write(data)
        Logger.log('Cache saved')
      end
    end

    def close
      if has_cache_file? && !cache_changed?
        Logger.log('No need to save cache again, because nothing has changed.')
        return
      end

      EyeDiff::Report.print_popularity(@cache)
      save_as_file
    end

    def has_cache_file?
      File.exists?(CACHEFILE)
    end

    def clear_cache
      @cache = {}
      File.delete(CACHEFILE)
    end

    def load_cache_from_file
      Logger.log('Loading cache from file')
      File.open(CACHEFILE, 'rb') do |f|
        @cache = Marshal.load(f.read)
        Logger.log('Loaded cache from file')
      end
    end
  end
end
