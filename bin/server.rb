#!/usr/bin/env ruby

lib = File.expand_path(File.join(__FILE__, '..', '..','lib'))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'eyediff'
require 'helper'
require 'xmlrpc/server'

class EyeDiffServer
  PORT = 3000

  class HandlerNames
    IDENTIFY = 'diff.identify'
    ADDREF   = 'diff.addreference'
  end

  class Handlers
    def initialize
      @cache = EyeDiff::Cache.new
    end

    def identify(encoded_data)
      image_data = Helper::Converter.to_binary(encoded_data)
      results = id_image(image_data)

      { message: results }
    end

    def add_reference(args)
      name   = args[0]
      images = []
      notes  = args[2]

      if EyeDiff::Security.is_path_malicious?(name)
        raise XMLRPC::FaultException(0, 'The reference path looks malicious.')
      end

      args[1].each { |item|
        item['data'] = Helper::Converter.to_binary(item['data'])
        images << Helper::Converter.hash_key_strings_to_symbols(item)
      }

      EyeDiff::References.add(name, images, notes)
      image_names = EyeDiff::References.get_image_paths(name)
      @cache.add(name: name, image_paths: image_names)

      { message: 'OK' }
    end

    def close
      @cache.close
      { messages: 'OK' }
    end

    def md5_match(image)
      @cache.each do |name, data|
        data[:images].each do |ref|
          diff = EyeDiff::Differ::MD5.new(image, ref[:md5])
          return name if diff.same?
        end
      end

      nil
    end

    def pixel_match(image)
      image = ChunkyPNG::Image.from_string(image)
      @cache.each do |name, data|
        data[:images].each do |ref|
          diff = EyeDiff::Differ::Pixel.new(image, ref[:png])
          return name if diff.same?
        end
      end

      nil
    end

    def id_image(image)
      EyeDiff::Logger.log("Identifying image...")

      name = md5_match(image) || pixel_match(image)
      if name
        EyeDiff::Logger.log("Found a match: #{name}")
        @cache.increase_popularity(name)
        notes = EyeDiff::References.get_notes(name)
        results = {}
        results[:name] = name
        results[:notes] = notes if notes
        return results
      end

      {}
    end

  end

  def self.run
    h = Handlers.new
    begin
      server = XMLRPC::Server.new(PORT)
      server.add_handler(EyeDiffServer::HandlerNames::IDENTIFY) { |encoded_data| h.identify(encoded_data) }
      server.add_handler(EyeDiffServer::HandlerNames::ADDREF) { |*args| h.add_reference(args) }
      server.set_default_handler { |name, *args| raise XMLRPC::FaultException.new(-99, 'Error') }
      server.serve
    ensure
      h.close
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  EyeDiffServer.run
end
