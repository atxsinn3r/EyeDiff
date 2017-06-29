module EyeDiff
  class Env

    def self.reference_directory
      File.expand_path(File.join(base, '..', 'references'))
    end

    def self.cache_file_location
      File.expand_path(File.join(base, '..', '.cache'))
    end

    def self.blacklist_file_location
      File.expand_path(File.join(base, '..', '.blacklist'))
    end

    def self.whitelist_file_location
      File.expand_path(File.join(base, '..', '.whitelist'))
    end

    def self.report_image_location
      File.expand_path(File.join(base, '..', 'report', 'images'))
    end

    def self.image_json_location
      File.expand_path(File.join(base, '..', 'report', 'image_data.json'))
    end

    def self.notes_json_location
      File.expand_path(File.join(base, '..', 'report', 'notes_data.json'))
    end

    def self.default_acceptable_pixel_difference
      7.3
    end

    def self.default_acceptable_histogram_difference
      {
        high: 100.0,
        low: 80.0
      }
    end

    def self.base
      File.expand_path(File.join(__FILE__, '..', '..'))
    end

  end
end
