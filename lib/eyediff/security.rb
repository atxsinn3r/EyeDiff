module EyeDiff
  class Security
    def self.is_path_malicious?(path)
      path.match(/\.\./) ? true : false
    end
  end
end
