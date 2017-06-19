module EyeDiff
  class Env

    def self.reference_directory
      File.expand_path(File.join(base, '..', 'references'))
    end

    def self.cache_file_location
      File.expand_path(File.join(base, '..', '.cache'))
    end

    def self.json_location
      File.expand_path(File.join(base, '..', 'report', 'data.json'))
    end

    def self.default_acceptable_difference
      10
    end

    def self.base
      File.expand_path(File.join(__FILE__, '..', '..'))
    end

  end
end
