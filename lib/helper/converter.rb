require 'base64'
require 'zlib'
require 'uri'

module Helper
  class Converter
    def self.hash_key_strings_to_symbols(h)
      h.map { |k,v| [k.to_sym,v] }.to_h
    end

    def self.decompress(data)
      Zlib::Inflate.inflate(data)
    end

    def self.compress(data)
      Zlib::Deflate.deflate(data)
    end

    def self.base64_encode(data)
      Base64.strict_encode64(data)
    end

    def self.pack_binary(data)
      base64_encode(compress(data))
    end

    def self.base64_decode(data)
      Base64.strict_decode64(data)
    end

    def self.to_binary(data)
      decompress(base64_decode(data))
    end

    def self.normalize_uri_filename(val)
      new_val = URI.unescape(val)
      new_val.gsub!(/:\/\//, '.')
      new_val.gsub!(/\//, '.')
      new_val
    end
  end
end
